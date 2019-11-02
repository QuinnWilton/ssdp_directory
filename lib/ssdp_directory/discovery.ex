defmodule SSDPDirectory.Discovery do
  alias __MODULE__
  alias SSDPDirectory.MulticastChannel

  def discover_services(service_type \\ "ssdp:all") do
    packet = Discovery.Request.encode(service_type)

    :ok = MulticastChannel.broadcast(packet)
  end
end
