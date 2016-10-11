use Mix.Releases.Config,
  default_release: :default,
  default_environment: :prod

environment :dev do
  set dev_mode: true
  set include_erts: false
  set cookie: :"development_cookie"
end

environment :prod do
  set include_erts: true
  set include_src: false
  set cookie: :"xA|O|y@g;/6F150[(5aY~Wa$;E:;Ah>/:pqq5Y_9`L^F%<?OmciH$&mXYtZ*fn:."
end

release :kv_store do
  set version: current_version(:kv_store)
end
