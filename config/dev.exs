use Mix.Config

config :kv_store,
  port: 8888,
  http_acceptors: 2,
  persistence: true,
  persistence_interval: 10_000,
  ttl_scanning_interval: 10_000

config :logger,
  level: :debug,
  handle_otp_reports: true,
  handle_sasl_reports: true,
  backends: [ :console ]
