defmodule SSDPDirectory.SearchResponse do
  alias __MODULE__

  alias SSDPDirectory.{
    Cache,
    HTTP,
    Service
  }

  @enforce_keys [:usn, :type]
  defstruct [:location] ++ @enforce_keys

  def decode(data) do
    case HTTP.decode_headers(data, []) do
      {:ok, headers, _rest} ->
        process_headers(headers)

      :error ->
        :error
    end
  end

  def handle(%SearchResponse{} = response) do
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
         %SearchResponse{
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
