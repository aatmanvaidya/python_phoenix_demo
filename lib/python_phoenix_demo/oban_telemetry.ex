defmodule PythonPhoenixDemo.ObanTelemetry do
  @moduledoc """
  Tracks Oban job metrics using Telemetry events.
  Stores metrics in an ETS table for easy retrieval.
  """

  use GenServer
  require Logger

  @table_name :oban_telemetry_metrics

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_metrics() do
    case :ets.info(@table_name) do
      :undefined ->
        %{queues: %{}, jobs: []}

      _ ->
        queues =
          case :ets.lookup(@table_name, :queues) do
            [{:queues, data}] -> data
            _ -> %{}
          end

        jobs =
          case :ets.lookup(@table_name, :recent_jobs) do
            [{:recent_jobs, data}] -> data
            _ -> []
          end

        %{queues: queues, jobs: jobs}
    end
  end

  # Server callbacks

  @impl GenServer
  def init(_) do
    # Create ETS table
    table = :ets.new(@table_name, [:set, :named_table, :public])
    :ets.insert(table, {:queues, %{}})
    :ets.insert(table, {:recent_jobs, []})

    # Attach telemetry handlers
    :telemetry.attach(
      "oban-job-start",
      [:oban, :job, :start],
      &handle_job_start/4,
      nil
    )

    :telemetry.attach(
      "oban-job-stop",
      [:oban, :job, :stop],
      &handle_job_stop/4,
      nil
    )

    :telemetry.attach(
      "oban-job-exception",
      [:oban, :job, :exception],
      &handle_job_exception/4,
      nil
    )

    :telemetry.attach(
      "oban-producer-started",
      [:oban, :producer, :started],
      &handle_producer_event/4,
      nil
    )

    {:ok, %{}}
  end

  # Telemetry handlers

  def handle_job_start(_event, _measurements, metadata, _config) do
    GenServer.cast(__MODULE__, {:job_start, metadata})
  end

  def handle_job_stop(_event, measurements, metadata, _config) do
    GenServer.cast(__MODULE__, {:job_stop, metadata, measurements})
  end

  def handle_job_exception(_event, _measurements, metadata, _config) do
    GenServer.cast(__MODULE__, {:job_exception, metadata})
  end

  def handle_producer_event(_event, _measurements, metadata, _config) do
    GenServer.cast(__MODULE__, {:producer_update, metadata})
  end

  # GenServer message handlers

  @impl GenServer
  def handle_cast({:job_start, metadata}, state) do
    # Extract job details
    queue = metadata.queue

    job = %{
      id: metadata.job.id,
      queue: queue,
      worker: metadata.job.worker,
      state: "running",
      args: metadata.job.args,
      started_at: DateTime.utc_now(),
      attempt: metadata.job.attempt
    }

    # Update queues metrics
    update_queue_metrics(queue, :running, :increment)

    # Add to recent jobs
    update_recent_jobs(job)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:job_stop, metadata, measurements}, state) do
    queue = metadata.queue

    # Create completed job record
    job = %{
      id: metadata.job.id,
      queue: queue,
      worker: metadata.job.worker,
      state: "completed",
      args: metadata.job.args,
      # Convert to ms
      duration: Float.round(measurements.duration / 1_000_000, 2),
      completed_at: DateTime.utc_now(),
      attempt: metadata.job.attempt
    }

    # Update metrics
    update_queue_metrics(queue, :running, :decrement)
    update_queue_metrics(queue, :completed, :increment)

    # Update job in recent jobs list
    update_recent_jobs(job)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:job_exception, metadata}, state) do
    queue = metadata.queue
    kind = metadata.kind

    job = %{
      id: metadata.job.id,
      queue: queue,
      worker: metadata.job.worker,
      state: "failed",
      error: inspect(metadata.error),
      args: metadata.job.args,
      failed_at: DateTime.utc_now(),
      kind: kind,
      attempt: metadata.job.attempt
    }

    # Update metrics
    update_queue_metrics(queue, :running, :decrement)
    update_queue_metrics(queue, :failed, :increment)

    # Update job in recent jobs list
    update_recent_jobs(job)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:producer_update, metadata}, state) do
    queue = metadata.queue
    limit = metadata.limit
    paused = metadata.paused

    # Update queue info
    [{:queues, queues}] = :ets.lookup(@table_name, :queues)
    queue_data = Map.get(queues, queue, %{completed: 0, failed: 0, running: 0})

    updated_queue =
      Map.merge(queue_data, %{
        limit: limit,
        paused: paused
      })

    :ets.insert(@table_name, {:queues, Map.put(queues, queue, updated_queue)})

    {:noreply, state}
  end

  # Helper functions

  defp update_queue_metrics(queue, metric, operation) do
    [{:queues, queues}] = :ets.lookup(@table_name, :queues)
    queue_data = Map.get(queues, queue, %{completed: 0, failed: 0, running: 0})

    current_value = Map.get(queue_data, metric, 0)

    new_value =
      case operation do
        :increment -> current_value + 1
        :decrement -> max(0, current_value - 1)
        {:set, value} -> value
      end

    updated_queue = Map.put(queue_data, metric, new_value)
    :ets.insert(@table_name, {:queues, Map.put(queues, queue, updated_queue)})
  end

  defp update_recent_jobs(job) do
    [{:recent_jobs, jobs}] = :ets.lookup(@table_name, :recent_jobs)

    # Remove old entry for this job if it exists
    updated_jobs = Enum.reject(jobs, fn j -> j.id == job.id end)

    # Add the new job entry
    updated_jobs = [job | updated_jobs]

    # Keep only the latest 100 jobs
    updated_jobs = Enum.take(updated_jobs, 100)

    :ets.insert(@table_name, {:recent_jobs, updated_jobs})
  end
end
