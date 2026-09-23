import Config

config :mega_elixir, MegaElixirWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4000"))],
  server: true
