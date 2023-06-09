defmodule Hello.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = OpentelemetryPhoenix.setup()

    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      # Start the Telemetry supervisor
      HelloWeb.Telemetry,
      # Start the Ecto repository
      Hello.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Hello.PubSub},
      # Start Finch
      {Finch, name: Hello.Finch},
      # Start presence after pubsub and before endpoint
      HelloWebApp.Presence,
      # Start the Endpoint (http/https)
      HelloWeb.Endpoint,
      # Start a worker by calling: Hello.Worker.start_link(arg)
      HelloWeb.UserTracker,
      # {Hello.Worker, arg}
      # Clustering setup
      {Cluster.Supervisor, [topologies, [name: Hello.ClusterSupervisor]]}
    ]

    children = _config_pipelines(children)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hello.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HelloWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def _config_pipelines(children) do
    case String.to_integer(System.get_env("PIPELINES") || "0") do
      1 ->
        children ++ [Hello.Pipeline.Inventory, Hello.Pipeline.Simple]
      _ ->
        children
    end
  end
end
