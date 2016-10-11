defmodule KvStore.MapReduce.WordCounter do
  alias Experimental.Flow

  @doc """
  Starts new word counting job with use of new `GenState` and
  `Flow` *Elixir* libraries
  """
  def start(parent, job_id, bucket, key_name) do
    per_line = Flow.Window.global |> Flow.Window.trigger_every(1, :reset)

    pid = spawn(fn() ->
      result = KvStore.Bucket.get_stream(bucket, key_name)
               |> Flow.from_enumerable(window: per_line)
               |> Flow.flat_map(&String.split(&1, " "))
               |> Flow.reduce(fn() -> %{} end, &update_word_count/2)
               |> Enum.to_list()
               |> Enum.map(&tuple_to_list/1)

      GenServer.cast(parent, {:finished, job_id, result})
    end)

    {:ok, pid}
  end

  # Private functions.

  defp tuple_to_list(element) do
    Tuple.to_list(element)
  end

  defp update_word_count("", map),  do: map
  defp update_word_count(word, map) do
    Map.update(map, word, 1, &(&1 + 1))
  end
end
