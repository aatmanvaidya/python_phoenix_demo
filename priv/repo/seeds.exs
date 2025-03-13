# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PythonPhoenixDemo.Repo.insert!(%PythonPhoenixDemo.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias PythonPhoenixDemo.MediaPayload

data = [
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_ApplyEyeMakeup_g03_c01.avi",
    id: "a5cb2152-77cf-4898-8616-96c3d67c82fb",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_ApplyLipstick_g14_c03.avi",
    id: "be43e3c8-354d-4c55-8c0c-5d8fc5f43c9f",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_Archery_g16_c05.avi",
    id: "fa328003-65ff-4e7f-9c2e-6e1f29e1f5d8",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_BabyCrawling_g03_c01.avi",
    id: "dc7b2c14-62da-42b6-a4b8-3d48de12a1d0",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_BalanceBeam_g20_c03.avi",
    id: "a6c26889-bbe3-46b5-b1d5-7b8f44c7bc3d",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_BandMarching_g11_c05.avi",
    id: "56a2e260-d69f-4324-b40d-37f0295ad350",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_BaseballPitch_g24_c02.avi",
    id: "2d0cf228-9a34-469e-9d57-3644094c34a4",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_BasketballDunk_g14_c06.avi",
    id: "94d79235-0c9c-463f-97c4-6a68bc9f0d6f",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_Basketball_g18_c04.avi",
    id: "f5050972-847a-4f85-a1c8-3dcedd90c923",
    media_type: "video"
  },
  %{
    path:
      "https://github.com/tattle-made/feluda_datasets/raw/main/clustering-media/video/v_BenchPress_g05_c04.avi",
    id: "3db8c15a-e5ed-4c3d-8206-1cb9538f2f93",
    media_type: "video"
  }
]

Enum.each(data, fn item ->
  case MediaPayload.create_media_payload(item) do
    {:ok, _record} -> IO.puts("Inserted: #{item.id}")
    {:error, changeset} -> IO.inspect(changeset.errors)
  end
end)
