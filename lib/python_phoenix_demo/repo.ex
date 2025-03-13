defmodule PythonPhoenixDemo.Repo do
  use Ecto.Repo,
    otp_app: :python_phoenix_demo,
    adapter: Ecto.Adapters.Postgres
end
