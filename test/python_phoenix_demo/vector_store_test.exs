defmodule PythonPhoenixDemo.VectorStoreTest do
  use ExUnit.Case
  alias PythonPhoenixDemo.VectorStore
  alias PythonPhoenixDemo.MediaEmbedding
  require Logger

  @moduledoc """
  Test suite for the VectorStore module.
  Tests vector index initialization, addition, searching, and management.
  """

  @test_index_name "test_images"
  @test_image_path "https://github.com/aatmanvaidya/audio-files/raw/main/images/1.jpeg"
  @test_dimension 512

  describe "init_index" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "successfully initializes a new index" do
      {:ok, index} = VectorStore.init_index(@test_index_name, @test_dimension)
      assert index != nil

      # Verify the index was created
      {:ok, stats} = VectorStore.get_index_stats(@test_index_name)
      assert stats.name == @test_index_name
      assert stats.dimension == @test_dimension
      assert stats.vector_count == 0
    end

    test "successfully loads an existing index" do
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)
      # Then try to load it again
      {:ok, index} = VectorStore.init_index(@test_index_name, @test_dimension)
      assert index != nil
      # Verify it's the same index
      {:ok, stats} = VectorStore.get_index_stats(@test_index_name)
      assert stats.dimension == @test_dimension
    end
  end

  describe "add_vector" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "successfully adds a vector to the index" do
      # Create the index
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      # Create a mock vector (would normally come from an embedding function)
      mock_vector = for _ <- 1..@test_dimension, do: :rand.uniform()

      # Add the vector
      assert :ok = VectorStore.add_vector(@test_index_name, mock_vector)

      # Verify it was added
      {:ok, stats} = VectorStore.get_index_stats(@test_index_name)
      assert stats.vector_count == 1
    end

    test "returns error when adding to non-existent index" do
      # Create a mock vector
      mock_vector = for _ <- 1..@test_dimension, do: :rand.uniform()

      # Try to add to a non-existent index
      result = VectorStore.add_vector("non_existent_index", mock_vector)
      assert {:error, _} = result
    end

    test "successfully adds image embedding from MediaEmbedding module" do
      # Initialize the index
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      # Get real embedding from the image
      case MediaEmbedding.get_image_embedding(@test_image_path) do
        {:error, reason} ->
          flunk("Failed to get image embedding: #{inspect(reason)}")

        embedding when is_list(embedding) ->
          # Check if the embedding has the expected dimension
          assert length(embedding) == @test_dimension

          # Add the embedding to the vector store
          result = VectorStore.add_vector(@test_index_name, embedding)
          assert result == :ok

          # Verify it was added
          {:ok, stats} = VectorStore.get_index_stats(@test_index_name)
          assert stats.vector_count == 1
      end
    end
  end

  describe "search" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "successfully searches for similar vectors" do
      # Initialize the index
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      # Add a few vectors
      for _id <- 1..5 do
        vector = for _ <- 1..@test_dimension, do: :rand.uniform()
        :ok = VectorStore.add_vector(@test_index_name, vector)
      end

      {:ok, _stats} = VectorStore.get_index_stats(@test_index_name)

      # Search using a random vector as query
      query_vector = for _ <- 1..@test_dimension, do: :rand.uniform()
      {:ok, results} = VectorStore.search(@test_index_name, query_vector, 4)

      assert Map.has_key?(results, :labels)
      assert Map.has_key?(results, :distances)
      labels = Nx.to_flat_list(results.labels)
      distances = Nx.to_flat_list(results.distances)
      assert length(labels) == 4
      assert length(distances) == 4
      assert distances == Enum.sort(distances)
    end

    test "searches with an image embedding from MediaEmbedding module" do
      # Initialize the index
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      # First, add some embeddings
      case MediaEmbedding.get_image_embedding(@test_image_path) do
        {:error, reason} ->
          flunk("Failed to get image embedding: #{inspect(reason)}")

        embedding when is_list(embedding) ->
          # Add the image embedding with ID 1
          :ok = VectorStore.add_vector(@test_index_name, embedding)

          # Add some random embeddings for comparison
          for _id <- 2..5 do
            random_vector = for _ <- 1..@test_dimension, do: :rand.uniform()
            :ok = VectorStore.add_vector(@test_index_name, random_vector)
          end

          # Now search using the same embedding as a query
          {:ok, results} = VectorStore.search(@test_index_name, embedding, 2)

          # The first result should be the exact match (ID 0)
          labels = Nx.to_flat_list(results.labels)
          assert Enum.at(labels, 0) == 0
          # The first distance should be very close to 0 (exact match)
          distances = Nx.to_flat_list(results.distances)
          assert Enum.at(distances, 0) < 0.001
      end
    end
  end

  describe "list_indices" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "returns all available indices" do
      # Create a couple of indices
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)
      {:ok, _} = VectorStore.init_index("#{@test_index_name}_2", @test_dimension)

      # List indices
      indices = VectorStore.list_indices()

      # Verify both indices are listed
      assert @test_index_name in indices
      assert "#{@test_index_name}_2" in indices
    end
  end

  describe "get_index_stats/1" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "returns correct statistics for an index" do
      # Create index
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      # Add some vectors
      for _id <- 1..3 do
        vector = for _ <- 1..@test_dimension, do: :rand.uniform()
        :ok = VectorStore.add_vector(@test_index_name, vector)
      end

      # Get stats
      {:ok, stats} = VectorStore.get_index_stats(@test_index_name)

      # Verify stats
      assert stats.name == @test_index_name
      assert stats.dimension == @test_dimension
      assert stats.vector_count == 3
      assert stats.file_size_bytes > 0
      assert String.ends_with?(stats.path, "#{@test_index_name}.faiss")
    end

    test "returns error for non-existent index" do
      result = VectorStore.get_index_stats("non_existent_index")
      assert {:error, _} = result
    end
  end

  describe "delete_index" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "successfully deletes an index" do
      # Create index
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      # Verify it exists
      indices_before = VectorStore.list_indices()
      assert @test_index_name in indices_before

      # Delete it
      :ok = VectorStore.delete_index(@test_index_name)

      # Verify it's gone
      indices_after = VectorStore.list_indices()
      refute @test_index_name in indices_after
    end

    test "returns error when deleting non-existent index" do
      result = VectorStore.delete_index("non_existent_index")
      assert {:error, _} = result
    end
  end

  describe "reset_index/3" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "successfully resets an index" do
      # Create index and add vectors
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      for _id <- 1..3 do
        vector = for _ <- 1..@test_dimension, do: :rand.uniform()
        :ok = VectorStore.add_vector(@test_index_name, vector)
      end

      # Verify vectors were added
      {:ok, stats_before} = VectorStore.get_index_stats(@test_index_name)
      assert stats_before.vector_count == 3

      # Reset index
      {:ok, _} = VectorStore.reset_index(@test_index_name, @test_dimension)

      # Verify it's empty
      {:ok, stats_after} = VectorStore.get_index_stats(@test_index_name)
      assert stats_after.vector_count == 0
      assert stats_after.dimension == @test_dimension
    end
  end

  describe "integration test with real image embeddings" do
    setup do
      # Make sure we start with a clean state
      _ = VectorStore.delete_index(@test_index_name)
      :ok
    end

    test "complete workflow with image embeddings" do
      # 1. Initialize the index
      {:ok, _} = VectorStore.init_index(@test_index_name, @test_dimension)

      # 2. Get image embedding from the test image
      case MediaEmbedding.get_image_embedding(@test_image_path) do
        {:error, reason} ->
          flunk("Failed to get image embedding: #{inspect(reason)}")

        embedding when is_list(embedding) ->
          # Verify dimension
          assert length(embedding) == @test_dimension

          # 3. Add the embedding with ID 1
          :ok = VectorStore.add_vector(@test_index_name, embedding)

          # 4. Get slightly modified version of the same embedding for a different ID
          # This simulates a similar but not identical image
          modified_embedding =
            Enum.map(embedding, fn val -> val * 0.95 + :rand.uniform() * 0.05 end)

          :ok = VectorStore.add_vector(@test_index_name, modified_embedding)

          # 5. Add some random embeddings
          for _id <- 3..5 do
            random_vector = for _ <- 1..@test_dimension, do: :rand.uniform()
            :ok = VectorStore.add_vector(@test_index_name, random_vector)
          end

          # 6. Search with the original embedding
          {:ok, results} = VectorStore.search(@test_index_name, embedding, 5)

          # 7. Verify search results
          labels = Nx.to_flat_list(results.labels)
          # First result should be the exact match (ID 1)
          assert Enum.at(labels, 0) == 0
          # Second result should be the similar embedding (ID 2)
          assert Enum.at(labels, 1) == 1

          # 8. Get stats and verify
          {:ok, stats} = VectorStore.get_index_stats(@test_index_name)
          assert stats.vector_count == 5

          # 9. Reset the index
          {:ok, _} = VectorStore.reset_index(@test_index_name, @test_dimension)

          # 10. Verify reset
          {:ok, stats_after} = VectorStore.get_index_stats(@test_index_name)
          assert stats_after.vector_count == 0
      end
    end
  end

  # Cleanup after all tests
  @tag :capture_log
  test "cleanup test indices" do
    indices = VectorStore.list_indices()

    for index_name <- indices do
      if String.contains?(index_name, "test_") do
        VectorStore.delete_index(index_name)
      end
    end

    # This is not really a test, just cleanup
    assert true
  end
end
