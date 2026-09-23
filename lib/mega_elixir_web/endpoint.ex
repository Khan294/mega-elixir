defmodule MegaElixirWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :mega_elixir

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug MegaElixirWeb.Router
end
