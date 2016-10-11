defmodule KvStore.HTTP.Router do
  use Plug.Router

  @moduledoc """
  Main application router built on top of `elixir-lang/plug` library.
  Underneath it uses `Cowboy` HTTP server.
  """

  plug Plug.Logger

  plug :match
  plug :dispatch

  forward "/bucket", to: KvStore.HTTP.BucketOperationsRouter
  forward "/buckets", to: KvStore.HTTP.BucketsRouter

  match _ do
    KvStore.HTTP.Helpers.not_found(conn)
  end
end
