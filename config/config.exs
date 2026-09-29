import Config

config :phoenix, :json_library, Jason

config :mega_elixir, MegaElixir.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4000"))],
  server: config_env() != :test
