defmodule PythonPhoenixDemo.Workers.MediaEmbeddingWorker do
  use Oban.Worker, queue: :media_embedding

  alias PythonPhoenixDemo.{MediaPayload, MediaEmbedding, VectorStore}
  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"media_id" => media_id}}) do
    # Fetch the media file from the database
    with %MediaPayload{} = media <- MediaPayload.get_media_payload!(media_id),
         # Check if the media type is image
         true <- media.media_type == "image",
         # Get the embedding
         embedding when is_list(embedding) <- MediaEmbedding.get_image_embedding(media.path),
         # Store the embedding in ExFaiss
         :ok <- VectorStore.add_vector("image", embedding) do
      Logger.info("Successfully processed media #{media_id} and stored its embedding")
      :ok
    else
      false ->
        Logger.warning("Media #{media_id} is not an image, skipping embedding")
        :ok

      {:error, reason} ->
        Logger.error("Failed to process media #{media_id}: #{inspect(reason)}")
        {:error, reason}

      error ->
        Logger.error("Unexpected error for media #{media_id}: #{inspect(error)}")
        {:error, "Processing failed"}
    end
  end
end
