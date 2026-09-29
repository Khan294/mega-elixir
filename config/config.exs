import Config

config :phoenix, :json_library, Jason

config :mega_elixir, ecto_repos: [MegaElixir.Repo]

config :mega_elixir, MegaElixir.Repo,
  url: System.get_env("DATABASE_URL", "ecto://postgres:postgres@localhost:5433/mega_elixir"),
  pool_size: 5

if config_env() == :test do
  config :mega_elixir, MegaElixir.Repo, pool: Ecto.Adapters.SQL.Sandbox
end

config :mega_elixir, MegaElixir.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4000"))],
  server: config_env() != :test
