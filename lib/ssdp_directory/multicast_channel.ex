defmodule SSDPDirectory.MulticastChannel do
  use GenServer

  alias __MODULE__

  alias SSDPDirectory.{
    Discovery,
    Presence
  }

  @multicast_group {239, 255, 255, 250}
  @multicast_port 1900

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def broadcast(channel \\ MulticastChannel, packet) do
    GenServer.cast(channel, {:broadcast, packet})
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

  def handle_cast({:broadcast, packet}, state) do
    :ok = :gen_udp.send(state.socket, @multicast_group, @multicast_port, packet)

    {:noreply, state}
  end

  def handle_info({:udp, _socket, _ip, _port, data}, state) do
    with {:ok, packet, rest} <- :erlang.decode_packet(:http_bin, data, []),
         {:ok, handler} <- packet_handler(packet),
         {:ok, decoded} <- handler.decode(rest) do
      :ok = handler.handle(decoded)
    end

    {:noreply, state}
  end

  defp packet_handler({:http_request, "NOTIFY", _target, _version}),
    do: {:ok, Presence}

  defp packet_handler({:http_response, _version, 200, "OK"}),
    do: {:ok, Discovery.Response}

  defp packet_handler(_packet), do: :error
end
