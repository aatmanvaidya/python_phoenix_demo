defmodule PythonPhoenixDemo.EmbeddingScheduler do
  @moduledoc """
  Schedules media files for embedding extraction and storage in ExFaiss.
  Provides functions to enqueue media files for processing.
  """

  alias PythonPhoenixDemo.{MediaPayload, VectorStore, Workers.MediaEmbeddingWorker}
  require Logger

  @doc """
  Enqueues all media files for embedding extraction.
  Initializes the vector index if it doesn't exist.
  """
  def enqueue_all_media() do
    # Initialize the vector index for images (using 512 as dimension for ResNet embeddings)
    # Adjust dimension based on your actual embedding size
    {:ok, _} = VectorStore.init_index("image", 512)

    # Get all media payloads from the database
    media_files = MediaPayload.list_media_payloads()
    total = length(media_files)

    Logger.info("Enqueueing #{total} media files for embedding extraction")

    # Enqueue each media file
    results =
      Enum.map(media_files, fn media ->
        %{media_id: media.id}
        |> MediaEmbeddingWorker.new()
        |> Oban.insert()
      end)

    successful =
      Enum.count(results, fn
        {:ok, _} -> true
        _ -> false
      end)

    Logger.info("Successfully enqueued #{successful}/#{total} media files")

    {:ok, %{total: total, successful: successful}}
  end

  @doc """
  Enqueues a single media file for embedding extraction.
  """

  def enqueue_media(media_id) do
    %{media_id: media_id}
    |> MediaEmbeddingWorker.new()
    |> Oban.insert()
  end

  @doc """
  Processes all media files and waits for completion.
  Useful for testing or small batches.
  """
  def process_all_media_sync() do
    # Initialize the vector index
    {:ok, _} = VectorStore.init_index("image", 512)

    # Get all media payloads from the database
    media_files = MediaPayload.list_media_payloads()

    Enum.each(media_files, fn media ->
      case MediaEmbeddingWorker.perform(%Oban.Job{args: %{"media_id" => media.id}}) do
        :ok ->
          Logger.info("Successfully processed media #{media.id}")

        {:error, reason} ->
          Logger.error("Failed to process media #{media.id}: #{inspect(reason)}")
      end
    end)
  end
end
