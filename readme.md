# MegaElixir

Minimal CRUD JSON API (no database) demonstrating the service–repository pattern.

## Install

1. Install Elixir (bundles Erlang/OTP): `choco install elixir` — or the installer from [elixir-lang.org](https://elixir-lang.org/install.html#windows).
2. `mix deps.get`

## Run

- `mix test` — run the tests
- `mix phx.server` — start the API at http://localhost:4000

## API

| Method     | Path             | Action |
| ---------- | ---------------- | ------ |
| GET        | /api/users       | list   |
| GET        | /api/users/:id   | show   |
| POST       | /api/users       | create |
| PUT/PATCH  | /api/users/:id   | update |
| DELETE     | /api/users/:id   | delete |

Create/update body: `{"user": {"name": "...", "email": "..."}}`.

## Structure

- `lib/mega_elixir/users.ex` — `Users` service: validation + business rules
- `lib/mega_elixir/users/` — `User` struct and in-memory `Repository` (data layer)
- `lib/mega_elixir_web/` — endpoint, router, controllers (JSON API)
