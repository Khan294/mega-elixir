# MegaElixir

Showcase project.

## Install Elixir (Windows)

1. `choco install elixir` (bundles Erlang/OTP) — or use the installer from [elixir-lang.org/install](https://elixir-lang.org/install.html#windows).
2. Verify: `elixir --version`

## Run

- `mix test` — run tests
- `iex -S mix` — REPL with the project loaded

## Structure

- `mix.exs` — project config (name, version, dependencies)
- `lib/` — source code; `mega_elixir.ex` defines the `MegaElixir` module
- `test/` — tests (ExUnit)
- `.formatter.exs` — code-formatting rules
- `.gitignore` — files git should ignore
