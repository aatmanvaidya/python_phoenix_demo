defmodule PythonPhoenixDemoWeb.ObanTelemetryLive do
  use PythonPhoenixDemoWeb, :live_view
  alias PythonPhoenixDemo.ObanTelemetry

  @refresh_interval 2000

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Schedule periodic updates
      Process.send_after(self(), :update, @refresh_interval)
    end

    metrics = ObanTelemetry.get_metrics()

    {:ok,
     assign(socket,
       queues: metrics.queues,
       jobs: metrics.jobs,
       selected_queue: "all",
       page_title: "Oban Telemetry Dashboard"
     )}
  end

  @impl true
  def handle_info(:update, socket) do
    # Schedule the next update
    Process.send_after(self(), :update, @refresh_interval)

    # Get latest metrics
    metrics = ObanTelemetry.get_metrics()

    {:noreply,
     assign(socket,
       queues: metrics.queues,
       jobs: filter_jobs(metrics.jobs, socket.assigns.selected_queue)
     )}
  end

  @impl true
  def handle_event("select-queue", %{"queue" => queue}, socket) do
    metrics = ObanTelemetry.get_metrics()

    {:noreply,
     assign(socket,
       selected_queue: queue,
       jobs: filter_jobs(metrics.jobs, queue)
     )}
  end

  defp filter_jobs(jobs, "all"), do: jobs
  defp filter_jobs(jobs, queue), do: Enum.filter(jobs, &(&1.queue == queue))

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <h1 class="text-3xl font-bold mb-6">Oban Telemetry Dashboard</h1>
      
    <!-- Queue Stats -->
      <div class="mb-8">
        <h2 class="text-xl font-semibold mb-4">Queue Statistics</h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <%= for {queue_name, stats} <- @queues do %>
            <div class={"bg-white shadow rounded-lg p-4 border-l-4 #{queue_color(stats)}"}>
              <div class="flex justify-between items-center">
                <h3 class="font-medium text-lg">{queue_name}</h3>
                <span class={[
                  "px-2 py-1 text-xs rounded-full",
                  if(stats[:paused],
                    do: "bg-yellow-100 text-yellow-800",
                    else: "bg-green-100 text-green-800"
                  )
                ]}>
                  {if stats[:paused], do: "Paused", else: "Active"}
                </span>
              </div>
              <div class="mt-2 grid grid-cols-3 gap-2">
                <div class="text-center">
                  <div class="text-2xl font-bold">{Map.get(stats, :running, 0)}</div>
                  <div class="text-xs text-gray-500">Running</div>
                </div>
                <div class="text-center">
                  <div class="text-2xl font-bold">{Map.get(stats, :completed, 0)}</div>
                  <div class="text-xs text-gray-500">Completed</div>
                </div>
                <div class="text-center">
                  <div class="text-2xl font-bold">{Map.get(stats, :failed, 0)}</div>
                  <div class="text-xs text-gray-500">Failed</div>
                </div>
              </div>
              <div class="mt-3">
                <button
                  phx-click="select-queue"
                  phx-value-queue={queue_name}
                  class="text-sm text-blue-600 hover:text-blue-800"
                >
                  View Jobs
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>
      
    <!-- Job Listings -->
      <div>
        <div class="flex justify-between items-center mb-4">
          <h2 class="text-xl font-semibold">Recent Jobs ({@selected_queue})</h2>
          <div class="flex space-x-2">
            <button
              phx-click="select-queue"
              phx-value-queue="all"
              class={
                [
                  "px-3 py-1 text-sm rounded"
                ] ++
                  if @selected_queue == "all",
                    do: ["bg-blue-600 text-white"],
                    else: ["bg-gray-200 hover:bg-gray-300"]
              }
            >
              All Queues
            </button>
            <%= for {queue_name, _} <- @queues do %>
              <button
                phx-click="select-queue"
                phx-value-queue={queue_name}
                class={[
                  "px-3 py-1 text-sm rounded",
                  if(@selected_queue == queue_name,
                    do: "bg-blue-600 text-white",
                    else: "bg-gray-200 hover:bg-gray-300"
                  )
                ]}
              >
                {queue_name}
              </button>
            <% end %>
          </div>
        </div>

        <div class="bg-white shadow overflow-x-auto rounded-lg">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  ID
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Worker
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Queue
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  State
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Args
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Time
                </th>
                <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Attempt
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for job <- @jobs do %>
                <tr>
                  <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                    {job.id}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {format_worker(job.worker)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {job.queue}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class={job_state_class(job.state)}>
                      {job.state}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">
                    {inspect(job.args)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {format_time(job)}
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {job.attempt}
                  </td>
                </tr>
              <% end %>
              <%= if Enum.empty?(@jobs) do %>
                <tr>
                  <td colspan="7" class="px-6 py-4 text-center text-sm text-gray-500">
                    No jobs found
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions

  defp queue_color(stats) do
    cond do
      Map.get(stats, :failed, 0) > 0 -> "border-red-500"
      Map.get(stats, :running, 0) > 0 -> "border-blue-500"
      Map.get(stats, :paused, false) -> "border-yellow-500"
      true -> "border-green-500"
    end
  end

  defp job_state_class(state) do
    base_classes = "px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full"

    case state do
      "running" -> "#{base_classes} bg-blue-100 text-blue-800"
      "completed" -> "#{base_classes} bg-green-100 text-green-800"
      "failed" -> "#{base_classes} bg-red-100 text-red-800"
      _ -> "#{base_classes} bg-gray-100 text-gray-800"
    end
  end

  defp format_worker(worker) do
    worker
    |> to_string()
    |> String.split(".")
    |> List.last()
  end

  defp format_time(job) do
    cond do
      Map.has_key?(job, :duration) ->
        "#{job.duration}ms"

      Map.has_key?(job, :started_at) ->
        "Started #{format_datetime(job.started_at)}"

      Map.has_key?(job, :completed_at) ->
        "Completed #{format_datetime(job.completed_at)}"

      Map.has_key?(job, :failed_at) ->
        "Failed #{format_datetime(job.failed_at)}"

      true ->
        "Unknown"
    end
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end
end
