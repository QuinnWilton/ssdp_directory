defmodule SSDPDirectory.Presence.Alive do
  require Logger

  alias __MODULE__

  alias SSDPDirectory.{
    Cache,
    Service
  }

  @enforce_keys [:usn, :type]
  defstruct [:location] ++ @enforce_keys

  @type t :: %Alive{}

  @spec handle(Alive.t()) :: :ok
  def handle(%Alive{} = command) do
    _ = Logger.debug(fn -> "Handling ssdp:alive request: " <> inspect(command) end)

    service = %Service{
      usn: command.usn,
      type: command.type,
      location: command.location
    }

    :ok = Cache.insert(service)
  end
end
