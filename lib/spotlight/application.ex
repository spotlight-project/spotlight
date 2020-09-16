defmodule Spotlight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SpotlightWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Spotlight.PubSub},
      Spotlight.RequestTimeCollector
      # Start a worker by calling: Spotlight.Worker.start_link(arg)
      # {Spotlight.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Spotlight.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
