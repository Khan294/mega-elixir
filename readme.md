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

On Windows PowerShell, use `mix.bat` if execution policy blocks `mix.ps1`.
To use another port: `$env:PORT = "4001"; mix.bat phx.server`.
