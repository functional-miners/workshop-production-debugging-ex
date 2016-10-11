defmodule KvStore.PersistenceScannerTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, registry} = KvStore.Registry.start_link(String.to_atom("Test registry for #{context.test}"))
    {:ok, scanner} = KvStore.Persistence.Scanner.start_link(String.to_atom("Test scanner for #{context.test}"))

    {:ok, registry: registry, scanner: scanner}
  end

  test "If persistence scanner is created, it can be stopped without any errors", %{scanner: scanner} do
    KvStore.Persistence.Scanner.stop(scanner)
  end

  test "If persistence scanner is created, you should be able to save entry there", %{scanner: scanner} do
    KvStore.Persistence.Scanner.create(scanner, :c.pid(0, 0, 1), "empty_bucket")
  end
end
