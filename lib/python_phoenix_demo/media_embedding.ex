defmodule PythonPhoenixDemo.MediaEmbedding do
  alias Pythonx, as: Py
  require Logger

  def get_image_embedding(file_path) do
    {:ok, tmp_path} = Briefly.create(extname: ".yml")
    IO.inspect(tmp_path, label: "TMP PATHH")

    config_content = """
    operators:
      label: "Operators"
      parameters:
        - name: "image vectors"
          type: "image_vec_rep_resnet"
          parameters: { index_name: "image" }
    """

    File.write!(tmp_path, config_content)

    {result, _globals} =
      Py.eval(
        """
        from feluda import Feluda
        from feluda.models.media_factory import ImageFactory

        feluda = Feluda('#{tmp_path}')
        feluda.setup()

        image_obj = ImageFactory.make_from_url('#{file_path}')
        operator = feluda.operators.get()["image_vec_rep_resnet"]
        image_vec = operator.run(image_obj)
        image_vec.tolist()
        """,
        %{}
      )

    File.rm(tmp_path)
    Briefly.cleanup()

    case Py.decode(result) do
      list when is_list(list) ->
        list

      other ->
        Logger.error("Unexpected result type from Python: #{inspect(other)}")
        {:error, "Failed to convert image embedding to list"}
    end
  rescue
    e ->
      Logger.error("Error in image embedding: #{inspect(e)}")
      {:error, "Failed to get image embedding"}
  end
end
