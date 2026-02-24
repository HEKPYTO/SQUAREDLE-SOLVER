defmodule SquaredleSolver.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SquaredleSolverWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:squaredle_solver, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SquaredleSolver.PubSub},
      SquaredleSolver.DictionaryServer,
      SquaredleSolverWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: SquaredleSolver.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SquaredleSolverWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
