defmodule KvStore.HTTP.BucketsRouter do
  use Plug.Router

  @moduledoc """
  Router for CRUD operations related to list of buckets.
  """

  plug :match
  plug :dispatch

  post "/create/:bucket_name" do
    KvStore.Registry.create(KvStore.Registry, bucket_name)

    {:ok, bucket} = KvStore.Registry.lookup(KvStore.Registry, bucket_name)
    KvStore.Persistence.Scanner.create(KvStore.Persistence.Scanner, bucket, bucket_name)

    KvStore.HTTP.Helpers.created(conn, "Bucket '#{bucket_name}' successfully created.")
  end

  match _ do
    KvStore.HTTP.Helpers.not_found(conn)
  end
end
