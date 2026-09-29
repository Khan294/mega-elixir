defmodule MegaElixirTest do
  use ExUnit.Case, async: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MegaElixir.Repo)
  end

  test "GET /api/hello returns users from PostgreSQL" do
    user = MegaElixir.Repo.insert!(%MegaElixir.User{name: "Ali", email: "ali@example.com"})

    conn =
      Plug.Test.conn(:get, "/api/hello")
      |> MegaElixir.Endpoint.call([])

    assert conn.status == 200
    assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert %{"users" => users} = Jason.decode!(conn.resp_body)
    assert %{"id" => user.id, "name" => "Ali", "email" => "ali@example.com"} in users
  end
end
