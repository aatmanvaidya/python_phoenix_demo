defmodule PythonPhoenixDemo.VectorStore do
  @moduledoc """
  Handles operations related to vector storage and retrieval using ExFaiss.
  Provides functions for managing vector indexes for different media types.
  """

  alias ExFaiss.Index
  require Logger

  # Directory where indexes will be stored
  @index_directory "priv/exfaiss_vector_indices"
  @file_io_flag 0

  @doc """
  Initialize a new vector index for a specific media type.

  ## Parameters
    * `index_name` - Name of the index (e.g., "image", "video")
    * `dimension` - Dimension of the vectors to be stored (e.g., 512 for images)
    * `metric` - Distance metric to use (defaults to :l2 Euclidean distance)

  ## Examples
      iex> VectorStore.init_index("image", 512)
      {:ok, %ExFaiss.Index{}}
  """
  def init_index(index_name, dimension) do
    # Ensure directory exists
    File.mkdir_p!(@index_directory)

    index_path = index_filepath(index_name)

    # Check if index already exists
    if File.exists?(index_path) do
      # Load existing index
      Logger.info("Loading existing index: #{index_name}")
      index = Index.from_file(index_path, @file_io_flag)
      {:ok, index}
    else
      # Create a new index
      Logger.info("Creating new index: #{index_name} with dimension #{dimension}")
      index = Index.new(dimension, "Flat")

      # Save the index
      :ok = Index.to_file(index, index_path)

      {:ok, index}
    end
  rescue
    e ->
      Logger.error("Failed to initialize index #{index_name}: #{inspect(e)}")
      {:error, "Failed to initialize index"}
  end

  @doc """
  Add a vector to an index with an associated ID.

  ## Parameters
    * `index_name` - Name of the index to add the vector to
    * `vector` - The embedding vector to add
    * `id` - The ID to associate with this vector (e.g., database ID of the media)

  ## Examples
      iex> VectorStore.add_vector("image", [0.1, 0.2, ...], 1)
      :ok
  """

  def add_vector(index_name, vector) do
    index_path = index_filepath(index_name)

    with {:ok, index} <- get_index(index_name),
         tensor <- Nx.tensor([vector], type: {:f, 32}),
         index <- Index.add(index, tensor),
         :ok <- Index.to_file(index, index_path) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to add vector to #{index_name}: #{inspect(reason)}")
        {:error, "Failed to add vector"}
    end
  end

  def add_vector_with_id(index_name, vector, ids) do
    index_path = index_filepath(index_name)

    with {:ok, index} <- get_index(index_name),
         tensor <- Nx.tensor([vector], type: {:f, 32}),
         id_tensor <- Nx.tensor([ids], type: {:s, 64}),
         index <- Index.add_with_ids(index, tensor, id_tensor),
         :ok <- Index.to_file(index, index_path) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to add vector with idsto #{index_name}: #{inspect(reason)}")
        {:error, "Failed to add vector"}
    end
  end

  @doc """
  Search for similar vectors in an index.

  ## Parameters
    * `index_name` - Name of the index to search in
    * `query_vector` - The vector to search for
    * `k` - Number of results to return (default: 5)

  ## Examples
      iex> VectorStore.search("image", [0.1, 0.2, ...], 3)
      {:ok, %{distances: [0.5, 0.7, 0.9], ids: [1, 5, 7]}}
  """

  def search(index_name, query_vector, k \\ 5) do
    try do
      with {:ok, index} <- get_index(index_name),
           tensor <- Nx.tensor([query_vector], type: {:f, 32}) do
        result = Index.search(index, tensor, k)
        {:ok, result}
      else
        {:error, reason} ->
          Logger.error("Failed to search in index #{index_name}: #{inspect(reason)}")
          {:error, "Failed to search index"}
      end
    rescue
      e ->
        Logger.error("Exception during search in index #{index_name}: #{inspect(e)}")
        {:error, "Search operation failed"}
    end
  end

  @doc """
  Get statistics about an index.

  ## Parameters
    * `index_name` - Name of the index to get stats for

  ## Examples
      iex> VectorStore.get_index_stats("image")
      {:ok, %{
        name: "image",
        vector_count: 150,
        dimension: 512,
        metric: :l2,
        file_size_bytes: 307200
      }}
  """

  def get_index_stats(index_name) do
    index_path = index_filepath(index_name)

    if not File.exists?(index_path) do
      {:error, "Index does not exist"}
    else
      with {:ok, index} <- get_index(index_name) do
        # Get basic index information
        dimension = index.dim
        total_vectors = Index.get_num_vectors(index)

        # Get file size
        {:ok, %{size: file_size}} = File.stat(index_path)

        stats = %{
          name: index_name,
          vector_count: total_vectors,
          dimension: dimension,
          file_size_bytes: file_size,
          path: index_path
        }

        {:ok, stats}
      else
        {:error, reason} ->
          Logger.error("Failed to get stats for index #{index_name}: #{inspect(reason)}")
          {:error, "Failed to get index statistics"}
      end
    end
  end

  @doc """
  List all available indices.

  ## Examples
      iex> VectorStore.list_indices()
      ["image", "video", "text"]
  """

  def list_indices do
    @index_directory
    |> File.ls!()
    |> Enum.filter(fn file -> String.ends_with?(file, ".faiss") end)
    |> Enum.map(fn file -> String.replace(file, ".faiss", "") end)
  rescue
    _ -> []
  end

  @doc """
  Delete an index.

  ## Parameters
    * `index_name` - Name of the index to delete

  ## Examples
      iex> VectorStore.delete_index("image")
      :ok
  """
  def delete_index(index_name) do
    index_path = index_filepath(index_name)

    if File.exists?(index_path) do
      File.rm!(index_path)
      Logger.info("Index #{index_name} Deleted!")
      :ok
    else
      {:error, "Index does not exist"}
    end
  rescue
    e ->
      Logger.error("Failed to delete index #{index_name}: #{inspect(e)}")
      {:error, "Failed to delete index"}
  end

  @doc """
  Reset an index by removing all vectors.

  ## Parameters
    * `index_name` - Name of the index to reset
    * `dimension` - Dimension of the vectors
    * `metric` - Distance metric to use (defaults to :l2)

  ## Examples
      iex> VectorStore.reset_index("image", 512)
      {:ok, %ExFaiss.Index{}}
  """
  def reset_index(index_name, dimension) do
    # Delete the index if it exists
    _ = delete_index(index_name)

    # Create a new one
    init_index(index_name, dimension)
  end

  # Helper function to get an index
  def get_index(index_name) do
    index_path = index_filepath(index_name)

    if File.exists?(index_path) do
      {:ok, Index.from_file(index_path, @file_io_flag)}
    else
      {:error, "Index does not exist"}
    end
  rescue
    e ->
      Logger.error("Failed to load index #{index_name}: #{inspect(e)}")
      {:error, "Failed to load index"}
  end

  # Helper function to build the filepath for an index
  def index_filepath(index_name) do
    Path.join(@index_directory, "#{index_name}.faiss")
  end
end
