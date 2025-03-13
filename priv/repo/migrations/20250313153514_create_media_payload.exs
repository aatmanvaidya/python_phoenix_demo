defmodule PythonPhoenixDemo.Repo.Migrations.CreateMediaPayload do
  use Ecto.Migration

  def change do
    create table(:media_payload) do
      add :path, :string
      add :media_type, :string

      timestamps()
    end
  end
end
