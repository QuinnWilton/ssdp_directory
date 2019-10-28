defmodule SSDPDirectory do
  alias SSDPDirectory.Cache

  def list_services() do
    Cache.contents()
  end
end
