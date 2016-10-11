defmodule KvStore.Persistence.Scanner do
  use GenServer

  require Logger

  @moduledoc """
  Module which is responsible for storing keys history into `DETS` files.
  """

  # Client API.

  @doc """
  Starts the persistence scanner with `name`.
  """
  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  @doc """
  Ensures there is an entry for `key` in `bucket` with given `name`.
  """
  def create(server, bucket, name) when is_pid(bucket) do
    GenServer.cast(server, {:create, bucket, name})
  end

  @doc """
  Stops the persistence scanner.
  """
  def stop(server) do
    GenServer.stop(server)
  end

  # GenServer callbacks.

  def init(:ok) do
    buckets = %{}
    refs = %{}

    maybe_schedule_persistence()

    {:ok, {buckets, refs}}
  end

  def handle_cast({:create, bucket, name}, {buckets, refs}) do
    updated_buckets = Map.put(buckets, name, bucket)

    ref = Process.monitor(bucket)
    updated_refs = Map.put(refs, ref, name)

    {:noreply, {updated_buckets, updated_refs}}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, {buckets, refs}) when reason != :normal do
    {bucket_name, updated_refs} = Map.pop(refs, ref)
    updated_buckets = Map.delete(buckets, bucket_name)

    {:noreply, {updated_buckets, updated_refs}}
  end

  def handle_info(:tick, {buckets, refs}) do
    {:ok, buckets_fd} = :dets.open_file("storage/buckets.dets", type: :set)

    Logger.info("Persisting buckets list: #{inspect extract_list_of_buckets(buckets)}")

    :dets.insert(buckets_fd, extract_list_of_buckets(buckets))
    :ok = :dets.close(buckets_fd)

    for {name, bucket} <- buckets do
      {:ok, bucket_fd} = :dets.open_file("storage/#{name}.dets", type: :set)

      keys = KvStore.Bucket.keys(bucket)
      save_keys(bucket_fd, name, bucket, keys)

      :ok = :dets.close(bucket_fd)
    end

    maybe_schedule_persistence()

    {:noreply, {buckets, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Private functions.

  defp save_keys(_bucket_fd, name, _bucket, []) do
    Logger.info("\t No keys to save in following bucket: '#{name}'")
  end

  defp save_keys(bucket_fd, name, bucket, [ head | tail ] = keys) do
    save_keys(bucket_fd, name, bucket, keys, head, tail, [])
  end

  defp save_keys(bucket_fd, name, bucket, keys, key, [], saved_keys) do
    save_single_key(bucket_fd, name, bucket, keys, key, saved_keys)
  end

  defp save_keys(bucket_fd, name, bucket, keys, key, [ new_key | rest_keys ], saved_keys) do
    save_single_key(bucket_fd, name, bucket, keys, key, saved_keys)
    save_keys(bucket_fd, name, bucket, keys, new_key, rest_keys, saved_keys ++ [ key ])
  end

  defp save_single_key(bucket_fd, name, bucket, keys, key, saved_keys) do
    value = KvStore.Bucket.get(bucket, key)
    :dets.insert(bucket_fd, {key, value})

    Logger.info("\t Keys waiting to save: #{inspect :lists.subtract(keys, saved_keys)}")
    Logger.info("\t Persisting entry: bucket = '#{name}', name = '#{key}', value = '#{inspect value}'")
  end

  defp extract_list_of_buckets(buckets) do
    buckets
    |> Enum.map(fn({key, _value}) -> {key} end)
  end

  defp maybe_schedule_persistence() do
    persistence_enabled = Application.get_env(:kv_store, :persistence, false)
    persistence_interval = Application.get_env(:kv_store, :persistence_interval, 10_000)

    maybe_persist(persistence_enabled, persistence_interval)
  end

  defp maybe_persist(false, _interval) do
    Logger.info("Scanning persistence disabled.")
  end

  defp maybe_persist(true, interval) do
    Logger.info("Scanning persistence enabled with interval: #{interval} ms")
    Process.send_after(self(), :tick, interval)
  end
end
