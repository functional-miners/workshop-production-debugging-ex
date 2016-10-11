defmodule KvStore.HTTP.BucketOperationsRouter do
  use Plug.Router

  @moduledoc """
  Router for individual bucket operations.
  """

  plug :match
  plug :dispatch

  get "/:bucket_name/keys" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        keys = KvStore.Bucket.keys(bucket)
        KvStore.HTTP.Helpers.json(conn, keys)
    end
  end

  get "/:bucket_name/key/:key_name" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        case KvStore.Bucket.get(bucket, key_name) do
          nil   -> KvStore.HTTP.Helpers.not_found(conn)
          value -> KvStore.HTTP.Helpers.json(conn, value)
        end
    end
  end

  put "/:bucket_name/key/:key_name" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        {values, updated_conn} = KvStore.HTTP.Helpers.parse(conn)

        KvStore.Bucket.put(bucket, key_name, Poison.decode!(values))
        KvStore.HTTP.Helpers.created(updated_conn, "Key '#{key_name}' created successfully in '#{bucket_name}'.")
    end
  end

  put "/:bucket_name/key/:key_name/ttl/:expiration" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        {values, updated_conn} = KvStore.HTTP.Helpers.parse(conn)

        KvStore.Bucket.put(bucket, key_name, Poison.decode!(values))
        KvStore.TTL.Scanner.create(KvStore.TTL.Scanner, bucket, key_name, String.to_integer(expiration))

        KvStore.HTTP.Helpers.created(updated_conn, "Key '#{key_name}' created successfully in '#{bucket_name}'.")
    end
  end

  delete "/:bucket_name/key/:key_name" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        KvStore.Bucket.del(bucket, key_name)
        KvStore.HTTP.Helpers.ok(conn, "Key '#{key_name}' deleted successfully from '#{bucket_name}'.")
    end
  end

  post "/:bucket_name/job/word_count/:key_name" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        case KvStore.MapReduce.Scheduler.new_word_count_job(KvStore.MapReduce.Scheduler, bucket, key_name) do
          :error ->
            KvStore.HTTP.Helpers.not_found(conn);

          {:ok, job_id} ->
            KvStore.HTTP.Helpers.accepted(conn, "Job '#{job_id}' accepted.")
        end
    end
  end

  post "/:bucket_name/job/avg" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        {:ok, job_id} = KvStore.MapReduce.Scheduler.new_job(KvStore.MapReduce.Scheduler, :avg, bucket)
        KvStore.HTTP.Helpers.accepted(conn, "Job '#{job_id}' accepted.")
    end
  end

  post "/:bucket_name/job/sum" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, bucket} ->
        {:ok, job_id} = KvStore.MapReduce.Scheduler.new_job(KvStore.MapReduce.Scheduler, :sum, bucket)
        KvStore.HTTP.Helpers.accepted(conn, "Job '#{job_id}' accepted.")
    end
  end

  get "/:bucket_name/job/:job_id" do
    case KvStore.Registry.lookup(KvStore.Registry, bucket_name) do
      :error ->
        KvStore.HTTP.Helpers.not_found(conn);

      {:ok, _bucket} ->
        result = KvStore.MapReduce.Scheduler.get_job_result(KvStore.MapReduce.Scheduler, String.to_integer(job_id))
        KvStore.HTTP.Helpers.json(conn, result)
    end
  end

  match _ do
    KvStore.HTTP.Helpers.not_found(conn)
  end
end
