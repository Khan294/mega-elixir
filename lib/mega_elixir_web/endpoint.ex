defmodule MegaElixirWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mega_elixir

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json"],
    json_decoder: Phoenix.json_library()
  )

  plug(MegaElixirWeb.Router)
end
