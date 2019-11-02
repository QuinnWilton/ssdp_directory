defmodule SSDPDirectory.Discovery.Response do
  require Logger

  alias __MODULE__

  alias SSDPDirectory.{
    Cache,
    HTTP,
    Service
  }

  @enforce_keys [:usn, :type]
  defstruct [:location] ++ @enforce_keys

  @type t :: %Response{}

  @spec decode(binary) :: :error | {:ok, Response.t()}
  def decode(data) do
    case HTTP.decode_headers(data, []) do
      {:ok, headers, _rest} ->
        process_headers(headers)

      :error ->
        _ = Logger.debug(fn -> "Failed to decode SEARCH response: " <> inspect(data) end)

        :error
    end
  end

  @spec handle(Response.t()) :: :ok
  def handle(%Response{} = response) do
    _ = Logger.debug(fn -> "Handling SEARCH response: " <> inspect(response) end)

    service = %Service{
      usn: response.usn,
      type: response.type,
      location: response.location
    }

    :ok = Cache.insert(service)
  end

  defp process_headers(headers) do
    do_process_headers(headers, %{})
  end

  defp do_process_headers([], args) do
    case args do
      %{usn: usn, type: type} when not is_nil(usn) and not is_nil(type) ->
        {:ok,
         %Response{
           usn: usn,
           type: type,
           location: Map.get(args, :location)
         }}

      _ ->
        :error
    end
  end

  defp do_process_headers([{"al", location} | rest], args) do
    args = Map.put(args, :location, location)

    do_process_headers(rest, args)
  end

  defp do_process_headers([{"location", location} | rest], args) do
    args = Map.put(args, :location, location)

    do_process_headers(rest, args)
  end

  defp do_process_headers([{"st", type} | rest], args) do
    args = Map.put(args, :type, type)

    do_process_headers(rest, args)
  end

  defp do_process_headers([{"usn", usn} | rest], args) do
    args = Map.put(args, :usn, usn)

    do_process_headers(rest, args)
  end

  defp do_process_headers([_ | rest], args) do
    do_process_headers(rest, args)
  end
end
