defmodule KvStore.MapReduceTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, scheduler} = KvStore.MapReduce.Scheduler.start_link(String.to_atom("Test scheduler for #{context.test}"))
    {:ok, registry} = KvStore.Registry.start_link(String.to_atom("Test registry for #{context.test}"))
    {:ok, scheduler: scheduler, registry: registry}
  end

  test "If scheduler created, it can be stopped successfully", %{scheduler: scheduler} do
    KvStore.MapReduce.Scheduler.stop(scheduler)
  end

  test "After waiting for sum, you should get it", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "sum_bucket")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "sum_bucket")

    KvStore.Bucket.put(bucket, "f1", 1)
    KvStore.Bucket.put(bucket, "f2", 1)
    KvStore.Bucket.put(bucket, "f3", 1)

    {:ok, job_id} = KvStore.MapReduce.Scheduler.new_job(scheduler, :sum, bucket)

    Process.sleep(300)

    assert KvStore.MapReduce.Scheduler.get_job_result(scheduler, job_id) == 3
  end

  test "After waiting for average, you should get it", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "average_bucket")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "average_bucket")

    KvStore.Bucket.put(bucket, "f1", 5)
    KvStore.Bucket.put(bucket, "f2", 5)
    KvStore.Bucket.put(bucket, "f3", 5)

    {:ok, job_id} = KvStore.MapReduce.Scheduler.new_job(scheduler, :avg, bucket)

    Process.sleep(300)

    assert KvStore.MapReduce.Scheduler.get_job_result(scheduler, job_id) == 5
  end

  test "Aggregation should handle different types", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "strange_bucket")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "strange_bucket")

    KvStore.Bucket.put(bucket, "f1", 4.5)
    KvStore.Bucket.put(bucket, "f2", "foo")
    KvStore.Bucket.put(bucket, "f3", 5.5)
    KvStore.Bucket.put(bucket, "f4", true)
    KvStore.Bucket.put(bucket, "f5", 2.8)
    KvStore.Bucket.put(bucket, "f6", :strange)
    KvStore.Bucket.put(bucket, "f7", 2.2)
    KvStore.Bucket.put(bucket, "f8", 5)

    {:ok, job_id} = KvStore.MapReduce.Scheduler.new_job(scheduler, :avg, bucket)

    Process.sleep(2_000)

    assert KvStore.MapReduce.Scheduler.get_job_result(scheduler, job_id) == 2.5
  end

  test "Empty bucket average should fail", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "empty_bucket")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "empty_bucket")

    {:ok, job_id} = KvStore.MapReduce.Scheduler.new_job(scheduler, :avg, bucket)

    Process.sleep(300)

    assert KvStore.MapReduce.Scheduler.get_job_result(scheduler, job_id) == :failed
  end

  test "Empty bucket sum should not fail", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "empty_sum_bucket")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "empty_sum_bucket")

    {:ok, job_id} = KvStore.MapReduce.Scheduler.new_job(scheduler, :sum, bucket)

    Process.sleep(300)

    assert KvStore.MapReduce.Scheduler.get_job_result(scheduler, job_id) == 0
  end

  test "Word counter job started on string key should work", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "bucket_for_string_word_count")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "bucket_for_string_word_count")

    KvStore.Bucket.put(bucket, "key_with_long_string", "roses are red")

    {:ok, job_id} = KvStore.MapReduce.Scheduler.new_word_count_job(scheduler, bucket, "key_with_long_string")

    Process.sleep(300)

    assert KvStore.MapReduce.Scheduler.get_job_result(scheduler, job_id) == [ ["are", 1], ["red", 1], ["roses", 1] ]
  end

  test "Word counter job on non-existing key should return error", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "empty_bucket_for_string_word_count")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "empty_bucket_for_string_word_count")

    assert KvStore.MapReduce.Scheduler.new_word_count_job(scheduler, bucket, "missing_key") == :error
  end

  test "Word counter job on non-string key should treat it as string", %{scheduler: scheduler, registry: registry} do
    KvStore.Registry.create(registry, "bucket_for_other_word_count")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "bucket_for_other_word_count")

    KvStore.Bucket.put(bucket, "key_with_long_string", 1)

    {:ok, job_id} = KvStore.MapReduce.Scheduler.new_word_count_job(scheduler, bucket, "key_with_long_string")

    Process.sleep(300)

    assert KvStore.MapReduce.Scheduler.get_job_result(scheduler, job_id) == [ ["1", 1] ]
  end
end
