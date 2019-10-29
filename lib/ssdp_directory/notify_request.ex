defmodule SSDPDirectory.NotifyRequest do
  alias SSDPDirectory.{
    Cache,
    HTTP,
    Service
  }

  def decode(data) do
    case HTTP.decode_headers(data, []) do
      {:ok, headers, _rest} ->
        case process_headers(headers) do
          {nil, _args} ->
            :error

          {command, args} ->
            {:ok, {command, args}}
        end

      :error ->
        :error
    end
  end

  def handle({"ssdp:alive", args}) do
    service = struct(Service, args)

    :ok = Cache.insert(service)
  end

  def handle({"ssdp:byebye", args}) do
    service = struct(Service, args)

    :ok = Cache.delete(service)
  end

  defp process_headers(headers) do
    do_process_headers(headers, nil, %{})
  end

  defp do_process_headers([], command, args) do
    {command, args}
  end

  defp do_process_headers([{"nts", command} | rest], nil, args) do
    do_process_headers(rest, command, args)
  end

  defp do_process_headers([{"nt", type} | rest], command, args) do
    args = Map.put(args, :type, type)

    do_process_headers(rest, command, args)
  end

  defp do_process_headers([{"usn", usn} | rest], command, args) do
    args = Map.put(args, :usn, usn)

    do_process_headers(rest, command, args)
  end

  defp do_process_headers([{"al", location} | rest], command, args) do
    args = Map.put(args, :location, location)

    do_process_headers(rest, command, args)
  end

  defp do_process_headers([{"location", location} | rest], command, args) do
    args = Map.put(args, :location, location)

    do_process_headers(rest, command, args)
  end

  defp do_process_headers([_ | rest], command, args) do
    do_process_headers(rest, command, args)
  end
end
