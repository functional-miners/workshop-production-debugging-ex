defmodule KvStore.BucketTest do
  use ExUnit.Case, async: true

  test "If name is not an atom, bucket creation should throw" do
    assert_raise FunctionClauseError, fn() -> KvStore.Bucket.start_link("NotAnAtom") end
  end

  test "If process under the name does not exist, get / put should throw" do
    assert_raise FunctionClauseError, fn() -> KvStore.Bucket.get(AnotherTestBucket, "foo") end
    assert_raise FunctionClauseError, fn() -> KvStore.Bucket.put(AnotherTestBucket, "foo", "bar") end
  end

  test "If key did not exist earlier, we should return `nil`" do
    {:ok, bucket} = KvStore.Bucket.start_link(NamedTestBucket)

    assert KvStore.Bucket.get(bucket, "foo") == nil
    assert KvStore.Bucket.get(NamedTestBucket, "foo") == nil
  end

  test "Bucket should store value under key" do
    {:ok, bucket} = KvStore.Bucket.start_link(NamedTestBucket)

    KvStore.Bucket.put(bucket, "foo", "bar")

    assert KvStore.Bucket.get(bucket, "foo") == "bar"
    assert KvStore.Bucket.get(NamedTestBucket, "foo") == "bar"
  end

  test "You should be able to delete existing key from the bucket by its `PID`" do
    {:ok, bucket} = KvStore.Bucket.start_link(NamedTestBucket)

    KvStore.Bucket.put(bucket, "foo", "bar")
    KvStore.Bucket.del(bucket, "foo")

    assert KvStore.Bucket.get(bucket, "foo") == nil
  end

  test "You should be able to delete existing key from the bucket by its `name`" do
    {:ok, _bucket} = KvStore.Bucket.start_link(NamedTestBucket)

    KvStore.Bucket.put(NamedTestBucket, "foo", "bar")
    KvStore.Bucket.del(NamedTestBucket, "foo")

    assert KvStore.Bucket.get(NamedTestBucket, "foo") == nil
  end

  test "Deleting non-existing key from the bucket by its `PID`, should not throw" do
    {:ok, bucket} = KvStore.Bucket.start_link(NamedTestBucket)

    KvStore.Bucket.del(bucket, "non_existing_key")

    assert KvStore.Bucket.get(bucket, "non_existing_key") == nil
  end

  test "Deleting non-existing key from the bucket by its `name`, should not throw" do
    {:ok, _bucket} = KvStore.Bucket.start_link(NamedTestBucket)

    KvStore.Bucket.del(NamedTestBucket, "non_existing_key")

    assert KvStore.Bucket.get(NamedTestBucket, "non_existing_key") == nil
  end

  test "Bucket should list all keys" do
    {:ok, bucket} = KvStore.Bucket.start_link(NamedTestBucket)

    KvStore.Bucket.put(bucket, "foo", 1)
    KvStore.Bucket.put(bucket, "bar", 2)
    KvStore.Bucket.put(bucket, "baz", 3)

    assert KvStore.Bucket.keys(bucket) == [ "bar", "baz", "foo" ]
    assert KvStore.Bucket.keys(NamedTestBucket) == [ "bar", "baz", "foo" ]
  end
end
