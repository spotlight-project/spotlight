defmodule Spotlight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: Spotlight.PubSub},
      {Spotlight.TelemetryPercentileCollector,
       [
         name: :web_request_duration,
         metric: [:phoenix, :endpoint, :stop],
         measurement: :duration
       ]},
      {Spotlight.TelemetryPercentileCollector,
       [
         name: :fake_ecto_query_duration,
         metric: [:ecto, :query, :complete],
         measurement: :duration
       ]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Spotlight.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
