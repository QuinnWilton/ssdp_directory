defmodule SSDPDirectory.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {SSDPDirectory.Cache, [name: SSDPDirectory.Cache]},
      {SSDPDirectory.MulticastChannel, [name: SSDPDirectory.MulticastChannel]}
    ]

    opts = [strategy: :one_for_one, name: SSDPDirectory.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl Application
  def start_phase(:discovery, _start_type, _phase_args) do
    :ok = SSDPDirectory.discover_services()
  end
end
