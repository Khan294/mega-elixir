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

  test "CSV upload imports quoted fields and skips existing and repeated emails" do
    email = "csv-#{System.unique_integer([:positive])}@example.com"
    existing_email = "existing-#{System.unique_integer([:positive])}@example.com"

    MegaElixir.Repo.insert!(%MegaElixir.User{
      name: "Existing",
      email: String.upcase(existing_email)
    })

    csv =
      "name,email\r\n\"Ali, Jr.\", #{String.upcase(email)} \r\nDuplicate,#{email}\r\nExisting,#{existing_email}\r\n"

    conn = upload(csv)

    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == %{"inserted" => 1, "skipped" => 2}
    assert MegaElixir.Repo.get_by!(MegaElixir.User, email: email).name == "Ali, Jr."
    assert Jason.decode!(upload(csv).resp_body) == %{"inserted" => 0, "skipped" => 3}
  end

  test "invalid CSV is rejected without inserting earlier valid rows" do
    email = "invalid-upload-#{System.unique_integer([:positive])}@example.com"
    conn = upload("name,email\nValid,#{email}\nInvalid,no-email\n")

    assert conn.status == 422
    assert MegaElixir.Repo.get_by(MegaElixir.User, email: email) == nil

    for csv <- [
          "wrong,headers\nAli,ali@example.com",
          "name,email\n",
          "name,email\nAli",
          "name,email\n\"unclosed",
          <<255>>
        ] do
      assert upload(csv).status == 422
    end
  end

  test "missing file is rejected" do
    conn = Plug.Test.conn(:post, "/api/users/import", %{}) |> MegaElixir.Endpoint.call([])
    assert conn.status == 400
  end

  defp upload(csv) do
    body =
      "--csv-boundary\r\n" <>
        "Content-Disposition: form-data; name=\"file\"; filename=\"users.csv\"\r\n" <>
        "Content-Type: text/csv\r\n\r\n" <> csv <> "\r\n--csv-boundary--\r\n"

    Plug.Test.conn(:post, "/api/users/import", body)
    |> Plug.Conn.put_req_header("content-type", "multipart/form-data; boundary=csv-boundary")
    |> MegaElixir.Endpoint.call([])
  end
end
