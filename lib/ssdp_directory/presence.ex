defmodule SSDPDirectory.Presence do
  require Logger

  alias __MODULE__
  alias SSDPDirectory.HTTP

  @type command :: Presence.Alive.t() | Presence.ByeBye.t()

  @spec decode(binary) ::
          :error
          | {:ok, command}
  def decode(data) do
    case HTTP.decode_headers(data, []) do
      {:ok, headers, _rest} ->
        process_headers(headers)

      :error ->
        _ = Logger.debug(fn -> "Failed to decode NOTIFY request: " <> inspect(data) end)

        :error
    end
  end

  @spec handle(command) :: :ok
  def handle(%Presence.Alive{} = command) do
    Presence.Alive.handle(command)
  end

  def handle(%Presence.ByeBye{} = command) do
    Presence.ByeBye.handle(command)
  end

  defp process_headers(headers) do
    do_process_headers(headers, %{})
  end

  defp do_process_headers([], args) do
    case args do
      %{command: "ssdp:alive", usn: usn, type: type}
      when not is_nil(usn) and not is_nil(type) ->
        {:ok,
         %Presence.Alive{
           usn: usn,
           type: type,
           location: Map.get(args, :location)
         }}

      %{command: "ssdp:byebye", usn: usn, type: type}
      when not is_nil(usn) and not is_nil(type) ->
        {:ok,
         %Presence.ByeBye{
           usn: usn,
           type: type
         }}

      _ ->
        :error
    end
  end

  defp do_process_headers([{"nts", command} | rest], args) do
    args = Map.put(args, :command, command)

    do_process_headers(rest, args)
  end

  defp do_process_headers([{"nt", type} | rest], args) do
    args = Map.put(args, :type, type)

    do_process_headers(rest, args)
  end

  defp do_process_headers([{"usn", usn} | rest], args) do
    args = Map.put(args, :usn, usn)

    do_process_headers(rest, args)
  end

  defp do_process_headers([{"al", location} | rest], args) do
    args = Map.put(args, :location, location)

    do_process_headers(rest, args)
  end

  defp do_process_headers([{"location", location} | rest], args) do
    args = Map.put(args, :location, location)

    do_process_headers(rest, args)
  end

  defp do_process_headers([_ | rest], args) do
    do_process_headers(rest, args)
  end
end
