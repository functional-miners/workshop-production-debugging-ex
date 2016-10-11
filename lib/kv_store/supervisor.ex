defmodule KvStore.Supervisor do
  use Supervisor

  @moduledoc """
  Main supervisor for our 'Key-Value Store' application.
  """

  # Client API.

  @doc """
  Starts the main supervisor.
  """
  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Supervisor callbacks.

  def init(:ok) do
    port = KvStore.Helpers.maybe_to_integer(Application.get_env(:kv_store, :port, 8888))
    acceptors = Application.get_env(:kv_store, :http_acceptors, 2)

    children = [
      worker(KvStore.Registry, [ KvStore.Registry ]),

      supervisor(KvStore.Bucket.Supervisor, []),
      Plug.Adapters.Cowboy.child_spec(:http, KvStore.HTTP.Router, [], [ port: port, acceptors: acceptors ]),

      worker(KvStore.TTL.Scanner, [ KvStore.TTL.Scanner ]),
      worker(KvStore.MapReduce.Scheduler, [ KvStore.MapReduce.Scheduler ]),
      worker(KvStore.Persistence.Scanner, [ KvStore.Persistence.Scanner ])
    ]

    supervise(children, strategy: :one_for_all)
  end
end
