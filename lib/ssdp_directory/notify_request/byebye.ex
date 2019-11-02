defmodule SSDPDirectory.NotifyRequest.ByeBye do
  alias __MODULE__

  alias SSDPDirectory.{
    Cache,
    Service
  }

  @enforce_keys [:usn, :type]
  defstruct @enforce_keys

  def handle(%ByeBye{} = command) do
    service = %Service{
      usn: command.usn,
      type: command.type
    }

    :ok = Cache.delete(service)
  end
end
