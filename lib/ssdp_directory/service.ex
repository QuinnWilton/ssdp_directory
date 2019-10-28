defmodule SSDPDirectory.Service do
  @enforce_keys [:usn, :type]
  defstruct [:usn, :type, :location]

  @opaque usn :: String.t()

  @type t :: %__MODULE__{
          usn: usn,
          type: String.t(),
          location: String.t()
        }
end
