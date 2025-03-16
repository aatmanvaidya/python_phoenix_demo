defmodule PythonPhoenixDemo.MediaEmbedding do
  alias Pythonx, as: Py
  require Logger

  def get_image_embedding(file_path) do
    # file_path =
    #   "https://tattle-media.s3.amazonaws.com/test-data/tattle-search/text-in-image-test-hindi.png"

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
        image_vec
        """,
        %{}
      )

    File.rm(tmp_path)
    Briefly.cleanup()

    decoded_result = Py.decode(result)
    decoded_result
  rescue
    e ->
      Logger.error("Error in image embedding: #{inspect(e)}")
      {:error, "Failed to get image embedding"}
  end
end
