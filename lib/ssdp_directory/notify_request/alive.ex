defmodule SSDPDirectory.NotifyRequest.Alive do
  alias __MODULE__

  alias SSDPDirectory.{
    Cache,
    Service
  }

  @enforce_keys [:usn, :type]
  defstruct [:location] ++ @enforce_keys

  def handle(%Alive{} = command) do
    service = %Service{
      usn: command.usn,
      type: command.type,
      location: command.location
    }

    :ok = Cache.insert(service)
  end
end
