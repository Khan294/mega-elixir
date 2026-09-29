# MegaElixir

Minimal Phoenix JSON API with PostgreSQL. Requires Elixir 1.20+ and Erlang/OTP.

The local database defaults are `localhost:5433`, username/password `postgres`,
and database `mega_elixir`. Override them with the `DATABASE_URL` environment
variable if needed. These defaults are for local learning only.

```sh
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Visit http://localhost:4000/api/hello:

```json
{"users":[]}
```

The API reads the `users` table. To add an example user, start `iex -S mix` (or
`iex.bat -S mix` on Windows) and run:

```elixir
MegaElixir.Repo.insert!(%MegaElixir.User{name: "Ali", email: "ali@example.com"})
```

Use this console instead of a separate server while inserting the user: it also
starts the application. Refresh `/api/hello` to see the stored row.

All application code, including the database connection module (`Repo`) and user
schema, lives in `lib/mega_elixir.ex`. Settings are in `config/config.exs` and the
table migration is in `priv/repo/migrations/`.

Run tests with `mix test` after migrating. The test inserts a user inside a
transaction that is rolled back afterward using Ecto's SQL Sandbox.

Import users with `POST /api/users/import`, using a multipart `file` field:

```csv
name,email
Ali,ali@example.com
Sara,sara@example.com
```

```powershell
curl.exe -F "file=@users.csv" http://localhost:4000/api/users/import
```

Returns `{"inserted":2,"skipped":0}`. Duplicate emails (ignoring case and outer
spaces) are skipped; the first occurrence wins. Files must be UTF-8, at most
1 MB, with exact `name,email` headers and 1–5000 data rows. Names must be nonblank;
emails must have a basic valid shape; both are limited to 255 characters. Invalid
rows reject the entire upload with HTTP 422. View imported users at `/api/hello`.

On Windows PowerShell, use `mix.bat` if execution policy blocks `mix.ps1`.
To use another port: `$env:PORT = "4001"; mix.bat phx.server`.
