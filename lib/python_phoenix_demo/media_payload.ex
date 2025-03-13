defmodule PythonPhoenixDemo.MediaPayload do
  use Ecto.Schema
  import Ecto.Changeset

  alias PythonPhoenixDemo.Repo

  schema "media_payload" do
    field :path, :string
    field :media_type, :string

    timestamps()
  end

  @doc """
  Changeset for validating media payloads.
  """
  def changeset(media_payload, attrs) do
    media_payload
    |> cast(attrs, [:path, :media_type])
    |> validate_required([:path, :media_type])
  end

  @doc """
  Insert a new media payload.
  """
  def create_media_payload(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Fetch all media payloads.
  """
  def list_media_payloads do
    Repo.all(__MODULE__)
  end

  @doc """
  Fetch a media payload by ID.
  """
  def get_media_payload!(id) do
    Repo.get!(__MODULE__, id)
  end
end
