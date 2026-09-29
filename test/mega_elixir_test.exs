defmodule MegaElixirTest do
  use ExUnit.Case, async: true

  test "GET /api/hello returns JSON" do
    conn =
      Plug.Test.conn(:get, "/api/hello")
      |> MegaElixir.Endpoint.call([])

    assert conn.status == 200
    assert Plug.Conn.get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert Jason.decode!(conn.resp_body) == %{"message" => "Hello, world!"}
  end
end
