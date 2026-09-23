import Config

config :mega_elixir, MegaElixirWeb.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [formats: [json: MegaElixirWeb.ErrorJSON], layout: false],
  secret_key_base: "dev-secret-do-not-use-in-prod"

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
