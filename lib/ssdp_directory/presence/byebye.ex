defmodule SSDPDirectory.Presence.ByeBye do
  require Logger

  alias __MODULE__

  alias SSDPDirectory.{
    Cache,
    Service
  }

  @enforce_keys [:usn, :type]
  defstruct @enforce_keys

  def handle(%ByeBye{} = command) do
    _ = Logger.debug(fn -> "Handling ssdp:byebye request: " <> inspect(command) end)

    service = %Service{
      usn: command.usn,
      type: command.type
    }

    :ok = Cache.delete(service)
  end
end
