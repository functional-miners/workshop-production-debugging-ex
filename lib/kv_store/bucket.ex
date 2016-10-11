defmodule KvStore.Bucket do
  @moduledoc """
  Module which is responsible for holding bucket state.
  Identifiable both by a name and PID.
  """

  @doc """
  Starts a new named bucket.
  """
  def start_link(name) when is_atom(name) do
    Agent.start_link(fn() -> %{} end, name: name)
  end

  @doc """
  Gets a stream of values from the `bucket` by `key` by PID.
  """
  def get_stream(bucket, key) when is_pid(bucket) do
    create_stream_from_value(Agent.get(bucket, &Map.get(&1, key)))
  end

  @doc """
  Gets a value from the `bucket` by `key` by PID.
  """
  def get(bucket, key) when is_pid(bucket) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Gets a value from the `bucket` by `key` by name.
  """
  def get(bucket, key) when is_atom(bucket) and bucket != nil do
    get(Process.whereis(bucket), key)
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket` by PID.
  """
  def put(bucket, key, value) when is_pid(bucket) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @doc """
  Puts the value for the given `key` in the `bucket` by name.
  """
  def put(bucket, key, value) when is_atom(bucket) and bucket != nil do
    put(Process.whereis(bucket), key, value)
  end

  @doc """
  Delete the given `key` in the `bucket` by PID.
  """
  def del(bucket, key) when is_pid(bucket) do
    Agent.update(bucket, &Map.delete(&1, key))
  end

  @doc """
  Delete the given `key` in the `bucket` by name.
  """
  def del(bucket, key) when is_atom(bucket) and bucket != nil do
    del(Process.whereis(bucket), key)
  end

  @doc """
  Get all keys in the `bucket` by PID.
  """
  def keys(bucket) when is_pid(bucket) do
    bucket
    |> Agent.get(&Map.to_list(&1))
    |> Enum.map(fn({key, _value}) -> key end)
    |> Enum.sort(&string_comparison/2)
  end

  @doc """
  Get all keys in the `bucket` by name.
  """
  def keys(bucket) when is_atom(bucket) and bucket != nil do
    keys(Process.whereis(bucket))
  end

  # Private functions.

  defp create_stream_from_value(value) do
    Stream.resource(fn () -> prepare_all_lines(value) end, &prepare_line/1, &noop/1)
  end

  defp convert(string) when is_binary(string), do: string
  defp convert(other), do: inspect(other)

  defp prepare_all_lines(long_string) do
    String.split(convert(long_string), "\n")
  end

  defp prepare_line(lines) do
    case Enum.count(lines) > 0 do
      true  ->
        line = Enum.take(lines, 1)
        rest = Enum.slice(lines, 1, Enum.count(lines))

        {line, rest};

      false ->
        {:halt, ""}
    end
  end

  defp noop(_empty_word_list) do
    nil
  end

  defp string_comparison(a, b) do
    Process.sleep(100)
    a < b
  end
end
