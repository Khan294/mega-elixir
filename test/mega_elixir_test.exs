defmodule MegaElixirTest do
  use ExUnit.Case, async: false
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest
  @endpoint MegaElixir.Endpoint

  setup do
    owner = Ecto.Adapters.SQL.Sandbox.start_owner!(MegaElixir.Repo, shared: true)
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(owner) end)
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

  test "API and LiveView show only the latest 10 users, descending by ID" do
    ids =
      for number <- 1..12 do
        MegaElixir.Repo.insert!(%MegaElixir.User{
          name: "User #{number}",
          email: "user#{number}@example.com"
        }).id
      end

    conn = Plug.Test.conn(:get, "/api/hello") |> MegaElixir.Endpoint.call([])

    assert Enum.map(Jason.decode!(conn.resp_body)["users"], & &1["id"]) ==
             Enum.take(Enum.reverse(ids), 10)

    {:ok, view, _html} = live(build_conn(), "/")
    refute has_element?(view, "#user-#{hd(ids)}")
    assert has_element?(view, "#user-#{List.last(ids)}")
  end

  test "native LiveView upload imports users, skips duplicates and refreshes the table" do
    email = "live-#{System.unique_integer([:positive])}@example.com"
    {:ok, view, _html} = live(build_conn(), "/")

    file =
      file_input(view, "#csv-form", :csv, [
        %{
          name: "users.csv",
          type: "text/csv",
          content: "name,email\nLive User,#{email}\nDuplicate,#{email}\n"
        }
      ])

    assert render_upload(file, "users.csv") =~ "100%"
    html = view |> form("#csv-form") |> render_submit()
    assert html =~ "Imported 1; skipped 1 duplicate(s)."
    assert has_element?(view, "tbody td", email)
  end

  test "native LiveView shows invalid CSV errors without inserting rows" do
    email = "live-invalid-#{System.unique_integer([:positive])}@example.com"
    {:ok, view, _html} = live(build_conn(), "/")

    file =
      file_input(view, "#csv-form", :csv, [
        %{
          name: "invalid.csv",
          type: "text/csv",
          content: "name,email\nValid,#{email}\nInvalid,not-an-email\n"
        }
      ])

    render_upload(file, "invalid.csv")
    assert view |> form("#csv-form") |> render_submit() =~ "Invalid name or email"
    assert MegaElixir.Repo.get_by(MegaElixir.User, email: email) == nil
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
