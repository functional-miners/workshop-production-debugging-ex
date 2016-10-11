defmodule KvStore.Mixfile do
  use Mix.Project

  def project do
    [
      app: :kv_store,
      version: "1.0.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      applications: apps(Mix.env) ++ apps_default(),
      mod: {KvStore, []}
    ]
  end

  defp apps(:dev),     do: [ :sasl ]
  defp apps(:prod),    do: [ :sasl ]
  defp apps(_),        do: []

  defp apps_default(), do: [ :logger, :gen_stage, :cowboy, :plug ]

  defp deps do
    [
      {:cowboy, "~> 1.0", override: true},
      {:plug, "~> 1.2"},
      {:poison, "~> 3.0"},

      {:distillery, "~> 0.10"},

      {:eper, "~> 0.94"},
      {:dbg, "~> 1.0"},
      {:recon, "~> 2.3"},
      {:recon_ex, "~> 0.9"},
      {:tap, "~> 0.1.4"},

      {:exprof, "~> 0.2"},

      {:erlubi, github: "krestenkrab/erlubi" },
      {:xprof, github: "appliscale/xprof" },

      {:gen_stage, "~> 0.4"}
    ]
  end
end
