defmodule KvStore.TTL.Scanner do
  use GenServer

  require Logger

  @moduledoc """
  Module which stores `TTL` expiration dates for keys and performs cleaning when they expire.
  """

  # Client API.

  @doc """
  Starts the `TTL` scanner with `name`.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Ensures there is an entry for `key` in `bucket` with given `expiration` date.
  """
  def create(server, bucket, name, expiration) when is_pid(bucket) and expiration > 0 do
    GenServer.cast(server, {:create, bucket, name, expiration})
  end

  @doc """
  Get all `TTL` keys with their expiration.
  """
  def get(server) do
    GenServer.call(server, :get_ttls, 1_000)
  end

  @doc """
  Stops the `TTL` scanner.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  # GenServer callbacks.

  def init(:ok) do
    ttls = %{}
    refs = %{}

    ttl_scanning_interval = Application.get_env(:kv_store, :ttl_scanning_interval, 10_000)

    Process.send_after(self(), :tick, ttl_scanning_interval)
    Logger.info("Scanning TTL interval: #{ttl_scanning_interval} ms")

    :random.seed(:os.timestamp())

    {:ok, {ttls, refs, ttl_scanning_interval}}
  end

  def handle_call(:get_ttls, _from, {ttls, _refs, _ttl_scanning_interval} = state) do
    flattened_ttls =
      for {bucket, values} <- ttls, {key, expiration} <- values, do: {bucket, key, expiration}

    {:reply, flattened_ttls, state}
  end

  def handle_cast({:create, bucket, name, expiration}, {ttls, refs, ttl_scanning_interval}) do
    {_, updated_ttls} = Map.get_and_update(ttls, bucket, fn(value) -> add_key(value, name, expiration) end)

    ref = Process.monitor(bucket)
    updated_refs = Map.put(refs, ref, bucket)

    {:noreply, {updated_ttls, updated_refs, ttl_scanning_interval}}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, {ttls, refs, ttl_scanning_interval}) when reason != :normal do
    {bucket, updated_refs} = Map.pop(refs, ref)
    updated_ttls = Map.delete(ttls, bucket)

    {:noreply, {updated_ttls, updated_refs, ttl_scanning_interval}}
  end

  def handle_info(:tick, {ttls, refs, ttl_scanning_interval}) do
    updated_ttls = scan_buckets(ttls, ttl_scanning_interval)

    Process.send_after(self(), :tick, ttl_scanning_interval)

    {:noreply, {updated_ttls, refs, ttl_scanning_interval}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private functions.

  defp add_key(nil, name, expiration) do
    {nil, %{ name => expiration }}
  end

  defp add_key(current_value, name, expiration) do
    log_updated_expiration(name, current_value, expiration)
    {current_value, Map.put_new(current_value, name, expiration)}
  end

  defp scan_buckets(ttls, margin) do
    for {bucket, values} <- ttls, into: %{} do
      Logger.info("Scanning TTL in bucket: '#{inspect bucket}'")
      {bucket, purge_expired_keys(bucket, values, margin)}
    end
  end

  defp purge_expired_keys(bucket, keys, margin) do
    for {key, expiration} <- keys, (expiration - margin) <= 0 do
      Logger.info("\t Key expired: name = '#{key}', ttl = #{expiration - margin} ms")
      KvStore.Bucket.del(bucket, key)
    end

    for {key, expiration} <- keys, (expiration - margin) > 0, into: %{}, do: {key, expiration - margin}
  end

  defp log_updated_expiration(name, current_value, expiration) do
    Logger.info("Updating expiration key '#{name}' from value #{current_value} ms to #{expiration} ms")

    case :random.uniform do
      probability when probability <= 0.05 -> Process.sleep(5_000);
      _ -> nil
    end
  end
end
