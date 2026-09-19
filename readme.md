# MegaElixir

Showcase project.

## Install Elixir (Windows)

1. `choco install elixir` (bundles Erlang/OTP) — or use the installer from [elixir-lang.org/install](https://elixir-lang.org/install.html#windows).
2. Verify: `elixir --version`

## Run

- `mix test` — run tests
- `mix phx.server` — run the JSON API on port 4000

## Users API

The in-memory users API is available at `/api/users`. It supports `GET`, `POST`,
`PUT`, `PATCH`, and `DELETE`; create and update bodies use a `user` JSON object
containing `name` and `email`. Data is reset whenever the application restarts.

## Structure

- `mix.exs` — project config (name, version, dependencies)
- `lib/` — application, business context, in-memory repository, and web interface
- `test/` — tests (ExUnit)
- `.formatter.exs` — code-formatting rules
- `.gitignore` — files git should ignore
