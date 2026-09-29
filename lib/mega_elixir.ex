defmodule MegaElixir do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([MegaElixir.Endpoint], strategy: :one_for_one)
  end
end

defmodule MegaElixir.HelloController do
  use Phoenix.Controller, formats: [:json]

  def index(conn, _params), do: json(conn, %{message: "Hello, world!"})
end

defmodule MegaElixir.Router do
  use Phoenix.Router

  get("/api/hello", MegaElixir.HelloController, :index)
end

defmodule MegaElixir.Endpoint do
  use Phoenix.Endpoint, otp_app: :mega_elixir

  plug(MegaElixir.Router)
end
