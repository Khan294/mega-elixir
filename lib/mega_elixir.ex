defmodule MegaElixir do
  use Application

  def start(_type, _args) do
    children = [MegaElixir.Repo, {Phoenix.PubSub, name: MegaElixir.PubSub}, MegaElixir.Endpoint]
    Supervisor.start_link(children, strategy: :one_for_one)
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

defmodule MegaElixir.Users do
  import Ecto.Query

  def latest do
    MegaElixir.Repo.all(from(user in MegaElixir.User, order_by: [desc: user.id], limit: 10))
    |> Enum.map(fn user -> Map.take(user, [:id, :name, :email]) end)
  end

  def import_csv(path) do
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

      {:ok, %{inserted: inserted, skipped: length(users) - inserted}}
    end
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

defmodule MegaElixir.HelloController do
  use Phoenix.Controller, formats: [:json]

  def index(conn, _params), do: json(conn, %{users: MegaElixir.Users.latest()})

  def import_csv(conn, %{"file" => %Plug.Upload{path: path}}) do
    case MegaElixir.Users.import_csv(path) do
      {:ok, result} ->
        json(conn, result)

      {:error, message} when is_binary(message) ->
        conn |> put_status(:unprocessable_entity) |> json(%{error: message})

      {:error, _} ->
        conn |> put_status(:bad_request) |> json(%{error: "Could not read uploaded file"})
    end
  end

  def import_csv(conn, _params) do
    conn |> put_status(:bad_request) |> json(%{error: "Upload a CSV using the file field"})
  end
end

defmodule MegaElixir.UsersLive do
  use Phoenix.LiveView, layout: false

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(users: MegaElixir.Users.latest(), message: "")
     |> allow_upload(:csv,
       accept: ~w(.csv),
       max_entries: 1,
       max_file_size: 1_000_000,
       auto_upload: true
     )}
  end

  def handle_event("validate", _params, socket), do: {:noreply, assign(socket, message: "")}

  def handle_event("cancel", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :csv, ref)}
  end

  def handle_event("import", _params, socket) do
    case uploaded_entries(socket, :csv) do
      {[_entry], []} ->
        [result] =
          consume_uploaded_entries(socket, :csv, fn %{path: path}, _entry ->
            {:ok, MegaElixir.Users.import_csv(path)}
          end)

        message =
          case result do
            {:ok, counts} ->
              "Imported #{counts.inserted}; skipped #{counts.skipped} duplicate(s)."

            {:error, error} when is_binary(error) ->
              error

            {:error, _} ->
              "Could not read uploaded file"
          end

        {:noreply, assign(socket, users: MegaElixir.Users.latest(), message: message)}

      _ ->
        {:noreply, assign(socket, message: "Choose a CSV and wait for the upload to finish.")}
    end
  end

  def render(assigns) do
    ~H"""
    <main>
      <h1>Users</h1>
      <section>
        <h2>Import a CSV</h2>
        <p>Headers: <code>name,email</code>. Up to 1 MB / 5,000 rows. Duplicate emails are skipped.</p>
        <form id="csv-form" phx-change="validate" phx-submit="import">
          <label for={@uploads.csv.ref}>CSV file</label>
          <.live_file_input upload={@uploads.csv} />
          <div :for={entry <- @uploads.csv.entries}>
            {entry.client_name} — {entry.progress}%
            <progress value={entry.progress} max="100" aria-label="Upload progress" />
            <button type="button" phx-click="cancel" phx-value-ref={entry.ref}>Remove</button>
            <p :for={error <- upload_errors(@uploads.csv, entry)} role="alert">{upload_error(error)}</p>
          </div>
          <p :for={error <- upload_errors(@uploads.csv)} role="alert">{upload_error(error)}</p>
          <button type="submit" phx-disable-with="Importing…"
            disabled={@uploads.csv.entries == [] or upload_errors(@uploads.csv) != [] or Enum.any?(@uploads.csv.entries, &(!&1.done? or !&1.valid?))}>
            Import CSV
          </button>
        </form>
        <p id="import-status" role="status">{@message}</p>
      </section>
      <section>
        <h2>Latest 10 users</h2>
        <p>Newest first.</p>
        <div class="table-wrap">
          <table>
            <thead><tr><th scope="col">ID</th><th scope="col">Name</th><th scope="col">Email</th></tr></thead>
            <tbody>
              <tr :for={user <- @users} id={"user-#{user.id}"}><td>{user.id}</td><td>{user.name}</td><td>{user.email}</td></tr>
              <tr :if={@users == []}><td colspan="3">No users yet. Import a CSV to get started.</td></tr>
            </tbody>
          </table>
        </div>
      </section>
    </main>
    """
  end

  defp upload_error(:too_large), do: "File must be at most 1 MB."
  defp upload_error(:not_accepted), do: "Choose a .csv file."
  defp upload_error(:too_many_files), do: "Choose one file at a time."
  defp upload_error(_), do: "Upload failed. Remove the file and try again."

  def root(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Plug.CSRFProtection.get_csrf_token()} />
        <title>Users · MegaElixir</title>
        <link rel="icon" href="data:," />
        <style phx-no-curly-interpolation>
          * { box-sizing: border-box; } body { margin: 0; font: 16px/1.5 system-ui, sans-serif; background: #f4f6f8; color: #182431; }
          main { max-width: 880px; margin: 40px auto; padding: 0 20px; }
          section { background: white; border: 1px solid #dce3e9; border-radius: 10px; padding: 24px; margin: 20px 0; }
          h2 { margin-top: 0; } p { color: #536273; } input { max-width: 100%; margin: 12px 0; }
          button { padding: 9px 16px; margin: 8px; background: #214dc2; color: white; border: 0; border-radius: 6px; cursor: pointer; }
          button:disabled { opacity: .5; cursor: default; } .table-wrap { overflow-x: auto; }
          table { width: 100%; border-collapse: collapse; text-align: left; } th, td { padding: 12px; border-bottom: 1px solid #e5e9ef; overflow-wrap: anywhere; }
          [role=alert] { color: #b42318; } :focus-visible { outline: 3px solid #718fff; outline-offset: 3px; }
        </style>
        <script type="module" phx-no-curly-interpolation>
          import {Socket} from "/assets/phoenix/phoenix.mjs";
          import {LiveSocket} from "/assets/live_view/phoenix_live_view.esm.js";
          new LiveSocket("/live", Socket, {params: {_csrf_token: document.querySelector('meta[name="csrf-token"]').content}}).connect();
        </script>
      </head>
      <body>{@inner_content}</body>
    </html>
    """
  end
end

defmodule MegaElixir.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:put_root_layout, html: {MegaElixir.UsersLive, :root})
  end

  scope "/" do
    pipe_through(:browser)
    live("/", MegaElixir.UsersLive)
  end

  get("/api/hello", MegaElixir.HelloController, :index)
  post("/api/users/import", MegaElixir.HelloController, :import_csv)
end

defmodule MegaElixir.Endpoint do
  use Phoenix.Endpoint, otp_app: :mega_elixir

  @session_options [
    store: :cookie,
    key: "_mega_elixir",
    signing_salt: "users-session",
    same_site: "Lax"
  ]
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])
  plug(Plug.Static, at: "/assets/phoenix", from: {:phoenix, "priv/static"}, only: ["phoenix.mjs"])

  plug(Plug.Static,
    at: "/assets/live_view",
    from: {:phoenix_live_view, "priv/static"},
    only: ["phoenix_live_view.esm.js"]
  )

  plug(Plug.Session, @session_options)
  plug(Plug.Parsers, parsers: [:multipart], length: 1_100_000)
  plug(MegaElixir.Router)
end
