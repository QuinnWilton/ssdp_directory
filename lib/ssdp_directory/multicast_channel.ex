defmodule SSDPDirectory.MulticastChannel do
  use GenServer

  require Logger

  alias __MODULE__

  alias SSDPDirectory.{
    NotifyRequest,
    SearchRequest,
    SearchResponse
  }

  @multicast_group {239, 255, 255, 250}
  @multicast_port 1900

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def discover(channel \\ MulticastChannel, service_type) when is_binary(service_type) do
    GenServer.cast(channel, {:discover, service_type})
  end

  def init(:ok) do
    udp_options = [
      :binary,
      active: true,
      add_membership: {@multicast_group, {0, 0, 0, 0}},
      multicast_if: {0, 0, 0, 0},
      multicast_loop: false,
      reuseaddr: true
    ]

    {:ok, socket} = :gen_udp.open(@multicast_port, udp_options)

    {:ok, %{socket: socket}}
  end

  def handle_cast({:discover, service_type}, state) when is_binary(service_type) do
    packet = SearchRequest.encode(service_type)

    case :gen_udp.send(state.socket, @multicast_group, @multicast_port, packet) do
      :ok ->
        _ = Logger.debug(fn -> "Sent search request for: " <> service_type end)

      {:error, reason} ->
        _ =
          Logger.debug(fn ->
            "Failed to send search request for: " <>
              service_type <> ", due to reason: " <> inspect(reason)
          end)
    end

    {:noreply, state}
  end

  def handle_info({:udp, _socket, _ip, _port, data}, state) do
    case :erlang.decode_packet(:http_bin, data, []) do
      {:ok, {:http_request, "NOTIFY", _target, _version}, rest} ->
        case NotifyRequest.decode(rest) do
          {:ok, request} ->
            _ = Logger.debug(fn -> "Decoded NOTIFY request: " <> inspect(request) end)

            :ok = NotifyRequest.handle(request)

          :error ->
            _ = Logger.debug(fn -> "Failed to decode NOTIFY request: " <> rest end)

            :ok
        end

      {:ok, {:http_response, _version, 200, "OK"}, rest} ->
        case SearchResponse.decode(rest) do
          {:ok, response} ->
            _ = Logger.debug(fn -> "Decoded M-SEARCH response: " <> inspect(response) end)

            :ok = SearchResponse.handle(response)

          :error ->
            _ = Logger.debug(fn -> "Failed to decode M-SEARCH response: " <> rest end)

            :ok
        end

      {:ok, {:http_request, "M-SEARCH", _target, _version}, _rest} ->
        :ok

      other ->
        _ = Logger.debug(fn -> "Received unknown message: " <> inspect(other) end)
        :ok
    end

    {:noreply, state}
  end
end
