defmodule SSDPDirectory do
  alias SSDPDirectory.{
    Cache,
    MulticastChannel
  }

  def discover_services(service_type \\ "ssdp:all") do
    MulticastChannel.discover(service_type)
  end

  def list_services() do
    Cache.contents()
  end
end
