defmodule MegaElixir do
  use Application

  def start(_type, _args) do
    Supervisor.start_link([MegaElixir.Repo, MegaElixir.Endpoint], strategy: :one_for_one)
  end
end

defmodule MegaElixir.Repo do
  use Ecto.Repo, otp_app: :mega_elixir, adapter: Ecto.Adapters.Postgres
end

defmodule MegaElixir.User do
  use Ecto.Schema

  schema "users" do
    field(:name, :string)
    field(:email, :string)
  end
end

defmodule MegaElixir.HelloController do
  use Phoenix.Controller, formats: [:json]
  import Ecto.Query

  def index(conn, _params) do
    users =
      MegaElixir.Repo.all(from(user in MegaElixir.User, order_by: user.id))
      |> Enum.map(fn user -> Map.take(user, [:id, :name, :email]) end)

    json(conn, %{users: users})
  end
end

defmodule MegaElixir.Router do
  use Phoenix.Router

  get("/api/hello", MegaElixir.HelloController, :index)
end

defmodule MegaElixir.Endpoint do
  use Phoenix.Endpoint, otp_app: :mega_elixir

  plug(MegaElixir.Router)
end
