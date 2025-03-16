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
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/1.jpeg",
    id: "ae8f0915-832f-4e50-bb55-e4b2c2d30625",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/2.jpeg",
    id: "d7fb90e7-7520-4761-8b89-d5d21b973d8a",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/3.jpeg",
    id: "f6d6064e-e097-44f1-b738-8917d5c1c829",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/4.png",
    id: "d12a1fd6-d20c-4b89-9f4e-842b49f03856",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/5.jpeg",
    id: "b6bbfe94-31e5-4a2d-8195-d967d03a85a8",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/6.jpeg",
    id: "d1f68565-8571-4c09-89aa-6a02da3fa51a",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/7.png",
    id: "4b6ec6c6-4f23-4b96-8b5b-5ecfa6a7b12d",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/8.jpeg",
    id: "db2de7b7-ec6e-4726-9397-84efdf45e357",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/9.jpeg",
    id: "aad83195-9095-4d72-8505-9a5d38e44c59",
    media_type: "image"
  },
  %{
    path: "https://github.com/aatmanvaidya/audio-files/raw/main/images/10.jpg",
    id: "4a4ff6d3-8b57-482a-a3d6-2fc85e82c1b8",
    media_type: "image"
  }
]

Enum.each(data, fn item ->
  case MediaPayload.create_media_payload(item) do
    {:ok, _record} -> IO.puts("Inserted: #{item.id}")
    {:error, changeset} -> IO.inspect(changeset.errors)
  end
end)
