defmodule SSDPDirectory.MulticastChannel do
  use GenServer

  require Logger

  alias SSDPDirectory.{
    HTTP,
    NotifyRequest
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
    case HTTP.decode_start_line(data) do
      {:ok, {{"NOTIFY", _target, _version}, rest}} ->
        case NotifyRequest.decode(rest) do
          {:ok, request} ->
            _ = Logger.debug(fn -> "Handling NOTIFY request: " <> inspect(request) end)

            :ok = NotifyRequest.handle(request)

          :error ->
            _ = Logger.debug(fn -> "Failed to parse invalid NOTIFY request: " <> rest end)

            :ok
        end

      _ ->
        :ok
    end

    {:noreply, state}
  end
end
