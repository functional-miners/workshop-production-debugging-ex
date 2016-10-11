defmodule KvStore do
  use Application

  @moduledoc """
  Module responsible for full-filling `Application` behavior.
  """

  # Application callbacks.

  @doc """
  Starts the KvStore application.
  """
  def start(_type, _args) do
    KvStore.Supervisor.start_link
  end
end
