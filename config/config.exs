import Config

config :mega_elixir, MegaElixirWeb.Endpoint,
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [formats: [json: MegaElixirWeb.ErrorJSON], layout: false],
  pubsub_server: MegaElixir.PubSub,
  secret_key_base: "QKfXrjvZ21oK0n2BrqIuub4tdWwJK8hzT63O7XfI8AwQHEhPsF2j2aq3aA7Qz1GR"

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
