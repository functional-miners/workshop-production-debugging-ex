defmodule KvStore.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, registry} = KvStore.Registry.start_link(context.test)
    {:ok, registry: registry}
  end

  test "Asking for a not existing bucket returns error", %{registry: registry} do
    assert KvStore.Registry.lookup(registry, "NotExistingBucket") == :error
  end

  test "Proper create call should spawn new bucket", %{registry: registry} do
    KvStore.Registry.create(registry, "EmptyBucket")

    assert {:ok, bucket} = KvStore.Registry.lookup(registry, "EmptyBucket")
    assert is_pid(bucket)
  end

  test "If bucket is created, we should be able to put there keys and values (by PID)", %{registry: registry} do
    KvStore.Registry.create(registry, "NewBucketByPID")

    {:ok, bucket} = KvStore.Registry.lookup(registry, "NewBucketByPID")
    KvStore.Bucket.put(bucket, "foo", "bar")

    assert KvStore.Bucket.get(bucket, "foo") == "bar"
  end

  test "If bucket is created, we should be able to put there keys and values (by name)", %{registry: registry} do
    KvStore.Registry.create(registry, "new_bucket")

    {:ok, bucket} = KvStore.Registry.lookup(registry, "new_bucket")
    KvStore.Bucket.put(:new_bucket, "foo", "bar")

    assert bucket == Process.whereis(:new_bucket)
    assert KvStore.Bucket.get(:new_bucket, "foo") == "bar"
  end

  test "If bucket will be stopped, it should be removed from registry", %{registry: registry} do
    KvStore.Registry.create(registry, "Schrodinger")

    {:ok, bucket} = KvStore.Registry.lookup(registry, "Schrodinger")
    Agent.stop(bucket)

    assert KvStore.Registry.lookup(registry, :Schrodinger) == :error
  end

  test "If bucket crashes, it should be removed from registry too", %{registry: registry} do
    KvStore.Registry.create(registry, "Crusher")

    {:ok, bucket} = KvStore.Registry.lookup(registry, "Crusher")

    ref = Process.monitor(bucket)
    Process.exit(bucket, :shutdown)

    assert_receive {:DOWN, ^ref, _, _, _}
    assert KvStore.Registry.lookup(registry, "Crusher") == :error
  end

  test "If registry is created, it can be stopped without any errors", %{registry: registry} do
    KvStore.Registry.stop(registry)
  end
end
