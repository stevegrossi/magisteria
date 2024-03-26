defmodule Magisteria.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MagisteriaWeb.Telemetry,
      Magisteria.Repo,
      {DNSCluster, query: Application.get_env(:magisteria, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Magisteria.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Magisteria.Finch},
      # Start a worker by calling: Magisteria.Worker.start_link(arg)
      # {Magisteria.Worker, arg},
      # Start to serve requests, typically the last entry
      MagisteriaWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Magisteria.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MagisteriaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
