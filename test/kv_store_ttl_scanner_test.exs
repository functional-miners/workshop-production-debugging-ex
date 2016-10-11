defmodule KvStore.TTLScannerTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, registry} = KvStore.Registry.start_link(String.to_atom("Test registry for #{context.test}"))
    {:ok, scanner} = KvStore.TTL.Scanner.start_link(String.to_atom("Test scanner for #{context.test}"))

    {:ok, registry: registry, scanner: scanner}
  end

  test "If scanner is created, it can be stopped without any errors", %{scanner: scanner} do
    KvStore.TTL.Scanner.stop(scanner)
  end

  test "Created entry should be removed after expiration time", %{registry: registry, scanner: scanner} do
   KvStore.Registry.create(registry, "foo")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "foo")

    KvStore.Bucket.put(bucket, "bar", "baz")
    KvStore.TTL.Scanner.create(scanner, bucket, "bar", 200)

    assert KvStore.Bucket.get(bucket, "bar") == "baz"

    Process.sleep(300)

    assert KvStore.Bucket.get(bucket, "bar") == nil
  end

  test "After waiting for everyone, state should be empty", %{registry: registry, scanner: scanner} do
    KvStore.Registry.create(registry, "multi_foo")
    {:ok, bucket} = KvStore.Registry.lookup(registry, "multi_foo")

    KvStore.Bucket.put(bucket, "bar1", 1)
    KvStore.Bucket.put(bucket, "bar2", 2)
    KvStore.Bucket.put(bucket, "bar3", 3)

    KvStore.TTL.Scanner.create(scanner, bucket, "bar1", 100)
    KvStore.TTL.Scanner.create(scanner, bucket, "bar2", 200)
    KvStore.TTL.Scanner.create(scanner, bucket, "bar3", 300)

    assert length(KvStore.TTL.Scanner.get(scanner)) == 3

    Process.sleep(101)

    assert length(KvStore.TTL.Scanner.get(scanner)) == 2

    Process.sleep(101)

    assert length(KvStore.TTL.Scanner.get(scanner)) == 1

    Process.sleep(101)

    assert length(KvStore.TTL.Scanner.get(scanner)) == 0
  end

  test "After bucket crash, it should clear all keys related to it", %{registry: registry, scanner: scanner} do
    KvStore.Registry.create(registry, "clearable_foo")
    {:ok, foo_bucket} = KvStore.Registry.lookup(registry, "clearable_foo")

    KvStore.Registry.create(registry, "clearable_bar")
    {:ok, bar_bucket} = KvStore.Registry.lookup(registry, "clearable_bar")

    KvStore.Bucket.put(foo_bucket, "key", "baz")
    KvStore.Bucket.put(bar_bucket, "key", "baz")

    KvStore.TTL.Scanner.create(scanner, foo_bucket, "key", 1_000)
    KvStore.TTL.Scanner.create(scanner, bar_bucket, "key", 1_000)

    assert length(KvStore.TTL.Scanner.get(scanner)) == 2

    ref = Process.monitor(bar_bucket)
    Process.exit(bar_bucket, :shutdown)

    assert_receive {:DOWN, ^ref, _, _, _}

    ttls = KvStore.TTL.Scanner.get(scanner)

    assert length(ttls) == 1
    assert [{^foo_bucket, "key", _}] = ttls
  end

  test "Created entries should be independent, even if the key name is the same", %{registry: registry, scanner: scanner} do
    KvStore.Registry.create(registry, "mixed_foo")
    {:ok, foo_bucket} = KvStore.Registry.lookup(registry, "mixed_foo")

    KvStore.Registry.create(registry, "mixed_bar")
    {:ok, bar_bucket} = KvStore.Registry.lookup(registry, "mixed_bar")

    KvStore.Bucket.put(foo_bucket, "bar", 1)
    KvStore.Bucket.put(bar_bucket, "bar", 2)

    KvStore.TTL.Scanner.create(scanner, foo_bucket, "bar", 200)
    KvStore.TTL.Scanner.create(scanner, bar_bucket, "bar", 500)

    assert KvStore.Bucket.get(foo_bucket, "bar") == 1
    assert KvStore.Bucket.get(bar_bucket, "bar") == 2

    Process.sleep(300)

    assert KvStore.Bucket.get(foo_bucket, "bar") == nil
    assert KvStore.Bucket.get(bar_bucket, "bar") == 2
  end
end
