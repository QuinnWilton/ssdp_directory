defmodule SSDPDirectory.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {SSDPDirectory.Cache, [name: SSDPDirectory.Cache]},
      {SSDPDirectory.Listener, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SSDPDirectory.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
