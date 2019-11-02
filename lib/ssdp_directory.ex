defmodule SSDPDirectory do
  alias SSDPDirectory.{
    Cache,
    Discovery
  }

  def discover_services(service_type \\ "ssdp:all") do
    Discovery.discover_services(service_type)
  end

  def list_services() do
    Cache.contents()
  end
end
