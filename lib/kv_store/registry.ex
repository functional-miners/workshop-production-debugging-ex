defmodule KvStore.Registry do
  use GenServer

  require Logger

  @moduledoc """
  Module representing server which holds all references to the buckets and allow to register new ones.
  """

  @vsn "1"

  # @vsn "2"

  # Client API.

  @doc """
  Starts the registry with `name`.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated to the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  # GenServer callbacks.

  def init(:ok) do
    names = %{}
    refs  = %{}

    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _refs} = state) do
    {:reply, Map.fetch(names, name), state}
  end

  def handle_cast({:create, name}, {names, refs}) do
     if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KvStore.Bucket.Supervisor.start_bucket(String.to_atom(name))

      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)

      names = Map.put(names, name, pid)

      {:noreply, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    # Logger.warn("Process ':DOWN' because of '#{inspect reason}' - pid = #{inspect pid}, reference = #{inspect ref}")
    {name, refs} = Map.pop(refs, ref)

    names = Map.delete(names, name)

    {:noreply, {names, refs}}
  end

  def code_change(old_vsn, state, extra) do
    Logger.warn("Code change - moving out of old version: '#{old_vsn}' - additional data passed: #{inspect extra}")
    {:ok, state}
  end
end
