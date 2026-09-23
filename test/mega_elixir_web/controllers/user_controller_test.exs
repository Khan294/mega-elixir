defmodule MegaElixirWeb.UserControllerTest do
  use ExUnit.Case, async: false

  import Phoenix.ConnTest

  alias MegaElixir.Users.Repository

  @endpoint MegaElixirWeb.Endpoint

  setup do
    Repository.reset()
    %{conn: Phoenix.ConnTest.build_conn()}
  end

  test "POST /api/users creates a user", %{conn: conn} do
    conn = post(conn, "/api/users", %{"user" => %{"name" => "Ada", "email" => "ada@example.com"}})

    assert conn.status == 201
    assert %{"id" => id, "name" => "Ada"} = json_response(conn, 201)["data"]
    assert is_integer(id)
  end

  test "GET /api/users lists users", %{conn: conn} do
    post(conn, "/api/users", %{"user" => %{"name" => "Ada", "email" => "ada@example.com"}})

    conn = get(conn, "/api/users")
    assert %{"data" => [_]} = json_response(conn, 200)
  end

  test "GET /api/users/:id shows a user", %{conn: conn} do
    %{"data" => %{"id" => id}} =
      post(conn, "/api/users", %{"user" => %{"name" => "Ada", "email" => "ada@example.com"}})
      |> json_response(201)

    conn = get(conn, "/api/users/#{id}")
    assert %{"data" => %{"id" => ^id, "name" => "Ada"}} = json_response(conn, 200)
  end

  test "PUT updates and DELETE removes a user", %{conn: conn} do
    %{"data" => %{"id" => id}} =
      post(conn, "/api/users", %{"user" => %{"name" => "Ada", "email" => "ada@example.com"}})
      |> json_response(201)

    conn =
      put(conn, "/api/users/#{id}", %{"user" => %{"name" => "Grace", "email" => "grace@example.com"}})

    assert %{"data" => %{"name" => "Grace"}} = json_response(conn, 200)

    conn = delete(conn, "/api/users/#{id}")
    assert conn.status == 204
  end

  test "returns 422 for an invalid payload", %{conn: conn} do
    conn = post(conn, "/api/users", %{"user" => %{"name" => "Ada"}})
    assert conn.status == 422
    assert %{"errors" => %{"email" => "can't be blank"}} = json_response(conn, 422)
  end

  test "returns 404 for a missing user", %{conn: conn} do
    conn = get(conn, "/api/users/999")
    assert conn.status == 404
  end
end
