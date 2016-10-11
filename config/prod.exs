use Mix.Config

config :kv_store,
  port: System.get_env("PORT"),
  http_acceptors: 100,
  persistence: true,
  persistence_interval: 1_000,
  ttl_scanning_interval: 1_000

config :logger,
  level: :warn,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  backends: [ :console ],
  compile_time_purge_level: :warn
