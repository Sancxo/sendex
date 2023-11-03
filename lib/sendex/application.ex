defmodule Sendex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  @impl true
  def start(_type, _args) do
    Logger.notice("Type Sendex.help() to get a hint on how to use the application.")

    children = [
      # Starts a worker by calling: Sendex.Worker.start_link(arg)
      # {Sendex.Worker, arg}
      {Finch, name: Swoosh.Finch}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sendex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
