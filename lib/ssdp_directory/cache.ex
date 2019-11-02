defmodule SSDPDirectory.Cache do
  use GenServer

  require Logger

  alias __MODULE__
  alias SSDPDirectory.Service

  def start_link(opts \\ []) do
    GenServer.start_link(Cache, :ok, opts)
  end

  def contents(cache \\ Cache) do
    :ets.tab2list(cache)
  end

  def insert(cache \\ Cache, %Service{} = service) do
    GenServer.call(cache, {:insert, service})
  end

  def delete(cache \\ Cache, %Service{} = service) do
    GenServer.call(cache, {:delete, service})
  end

  def flush(cache \\ Cache) do
    GenServer.call(cache, :flush)
  end

  def init(:ok) do
    table = :ets.new(Cache, [:named_table, read_concurrency: true])

    {:ok, %{table: table}}
  end

  def handle_call({:insert, %Service{usn: usn} = service}, _from, data) when not is_nil(usn) do
    :ets.insert(data.table, {usn, service})

    _ = Logger.debug(fn -> "Cached service: " <> inspect(usn) end)

    {:reply, :ok, data}
  end

  def handle_call({:delete, %Service{usn: usn}}, _from, data) when not is_nil(usn) do
    :ets.delete(data.table, usn)

    _ = Logger.debug(fn -> "Evicted service: " <> inspect(usn) end)

    {:reply, :ok, data}
  end

  def handle_call(:flush, _from, data) do
    :ets.delete_all_objects(data.table)

    _ = Logger.debug(fn -> "Flushed cache" end)

    {:reply, :ok, data}
  end
end
