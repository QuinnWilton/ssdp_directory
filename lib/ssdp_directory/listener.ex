defmodule SSDPDirectory.Listener do
  use GenServer

  alias SSDPDirectory.{
    Cache,
    Service
  }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    udp_options = [
      :binary,
      active: true,
      add_membership: {{239, 255, 255, 250}, {0, 0, 0, 0}},
      multicast_if: {0, 0, 0, 0},
      multicast_loop: false,
      reuseaddr: true
    ]

    {:ok, _socket} = :gen_udp.open(1900, udp_options)
  end

  def handle_info({:udp, _socket, _ip, _port, data}, state) do
    case :erlang.decode_packet(:http_bin, data, []) do
      {:ok, {:http_request, "NOTIFY", :*, {1, 1}}, rest} ->
        :ok = handle_notify(rest)
        {:noreply, state}

      {:ok, _other, _rest} ->
        {:noreply, state}

      {:more, _length} ->
        {:noreply, state}

      {:error, _error} ->
        {:noreply, state}
    end
  end

  defp handle_notify(data) do
    case decode_headers(data, []) do
      {:ok, headers} ->
        case process_headers(headers) do
          {nil, _args} ->
            :error

          {"ssdp:alive", args} ->
            handle_ssdp_alive(args)

          {"ssdp:byebye", args} ->
            handle_ssdp_byebye(args)
        end

      :error ->
        :error
    end
  end

  defp handle_ssdp_alive(args) do
    service = struct(Service, args)

    :ok = Cache.insert(service)
  end

  defp handle_ssdp_byebye(args) do
    service = struct(Service, args)

    :ok = Cache.delete(service)
  end

  defp decode_headers(data, headers) do
    case :erlang.decode_packet(:httph_bin, data, []) do
      {:ok, {:http_header, _unused, name, _reserved, value}, rest} ->
        headers = [{header_name(name), value} | headers]
        decode_headers(rest, headers)

      {:ok, :http_eoh, _rest} ->
        {:ok, headers}

      {:ok, _other, _rest} ->
        :error

      {:more, _length} ->
        :error

      {:error, _error} ->
        :error
    end
  end

  defp header_name(name) when is_atom(name), do: name |> Atom.to_string() |> header_name()
  defp header_name(name) when is_binary(name), do: downcase_ascii(name)

  # Lowercases an ASCII string more efficiently than
  # String.downcase/1.
  defp downcase_ascii(string),
    do: for(<<char <- string>>, do: <<downcase_ascii_char(char)>>, into: "")

  defp downcase_ascii_char(char) when char in ?A..?Z, do: char + 32
  defp downcase_ascii_char(char) when char in 0..127, do: char

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
