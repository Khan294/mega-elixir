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

  def import_csv(conn, %{"file" => %Plug.Upload{path: path}}) do
    with {:ok, contents} <- File.read(path),
         {:ok, users} <- csv_users(contents) do
      {:ok, inserted} =
        MegaElixir.Repo.transaction(fn ->
          # Serialize imports so simultaneous uploads cannot insert the same email.
          Ecto.Adapters.SQL.query!(
            MegaElixir.Repo,
            "LOCK TABLE users IN SHARE ROW EXCLUSIVE MODE"
          )

          emails = Enum.map(users, & &1.email)

          existing =
            MegaElixir.Repo.all(
              from(u in MegaElixir.User,
                where: fragment("lower(btrim(?))", u.email) in ^emails,
                select: fragment("lower(btrim(?))", u.email)
              )
            )
            |> MapSet.new()

          new_users =
            users |> Enum.uniq_by(& &1.email) |> Enum.reject(&MapSet.member?(existing, &1.email))

          {count, _} = MegaElixir.Repo.insert_all(MegaElixir.User, new_users)
          count
        end)

      json(conn, %{inserted: inserted, skipped: length(users) - inserted})
    else
      {:error, message} when is_binary(message) ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: message})

      {:error, _} ->
        conn |> put_status(:bad_request) |> json(%{error: "Could not read uploaded file"})
    end
  end

  def import_csv(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Upload a CSV using the file field"})
  end

  defp csv_users(contents) do
    if byte_size(contents) > 1_000_000 or not String.valid?(contents) do
      {:error, "CSV must be UTF-8 and at most 1 MB"}
    else
      case NimbleCSV.RFC4180.parse_string(String.trim_leading(contents, "\uFEFF"),
             skip_headers: false
           ) do
        [["name", "email"] | rows] when rows != [] and length(rows) <= 5_000 ->
          rows
          |> Enum.with_index(2)
          |> Enum.reduce_while({:ok, []}, fn
            {[name, email], line}, {:ok, users} ->
              name = String.trim(name)
              email = email |> String.trim() |> String.downcase()

              if name != "" and String.length(name) <= 255 and String.length(email) <= 255 and
                   Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, email) do
                {:cont, {:ok, [%{name: name, email: email} | users]}}
              else
                {:halt, {:error, "Invalid name or email at CSV row #{line}"}}
              end

            {_, line}, _ ->
              {:halt, {:error, "Expected two columns at CSV row #{line}"}}
          end)
          |> case do
            {:ok, users} -> {:ok, Enum.reverse(users)}
            error -> error
          end

        _ ->
          {:error, "Expected name,email headers and 1–5000 data rows"}
      end
    end
  rescue
    NimbleCSV.ParseError -> {:error, "Malformed CSV"}
  end
end

defmodule MegaElixir.Router do
  use Phoenix.Router

  get("/api/hello", MegaElixir.HelloController, :index)
  post("/api/users/import", MegaElixir.HelloController, :import_csv)
end

defmodule MegaElixir.Endpoint do
  use Phoenix.Endpoint, otp_app: :mega_elixir

  plug(Plug.Parsers, parsers: [:multipart], length: 1_100_000)
  plug(MegaElixir.Router)
end
