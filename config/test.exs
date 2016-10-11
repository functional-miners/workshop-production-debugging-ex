use Mix.Config

config :kv_store,
  port: 0,
  http_acceptors: 10,
  persistence: false,
  persistence_interval: 0,
  ttl_scanning_interval: 100

config :logger,
  level: :warn,
  handle_otp_reports: false,
  handle_sasl_reports: false,
  backends: [ :console ],
  compile_time_purge_level: :warn
