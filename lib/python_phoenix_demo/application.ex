defmodule PythonPhoenixDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PythonPhoenixDemoWeb.Telemetry,
      PythonPhoenixDemo.Repo,
      {DNSCluster,
       query: Application.get_env(:python_phoenix_demo, :dns_cluster_query) || :ignore},
      {Oban, Application.fetch_env!(:python_phoenix_demo, Oban)},
      PythonPhoenixDemo.ObanTelemetry,
      {Phoenix.PubSub, name: PythonPhoenixDemo.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PythonPhoenixDemo.Finch},
      # Start a worker by calling: PythonPhoenixDemo.Worker.start_link(arg)
      # {PythonPhoenixDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      PythonPhoenixDemoWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PythonPhoenixDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PythonPhoenixDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
