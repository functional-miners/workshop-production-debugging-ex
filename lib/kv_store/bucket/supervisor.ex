defmodule KvStore.Bucket.Supervisor do
  use Supervisor

  @moduledoc """
  Proper supervisor for all buckets managed by application.
  """

  # Client API.

  @doc """
  Starts the bucket supervisor.
  """
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Starts the bucket with prepared `named`.
  """
  def start_bucket(name) do
    Supervisor.start_child(__MODULE__, [ name ])
  end

  # Supervisor callbacks.

  def init(:ok) do
    children = [
      worker(KvStore.Bucket, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end
end
