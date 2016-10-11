defmodule KvStore.Helpers do
  require Logger

  @moduledoc """
  Various helpers for application logic.
  """

  @doc """
  Detect the value type and perform sum operation, if it is possible.
  """
  def maybe_sum(acc, value) when not is_integer(value) and not is_float(value), do: sum(acc)
  def maybe_sum(acc, value), do: acc + value

  @doc """
  Detect the type of value and convert to integer if necessary.
  """
  def maybe_to_integer(string) when is_binary(string), do: String.to_integer(string)
  def maybe_to_integer(integer) when is_integer(integer), do: integer

  # Private functions

  defp sum(acc) do
    Process.sleep(300)
    acc
  end
end
