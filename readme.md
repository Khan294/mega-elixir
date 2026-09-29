# MegaElixir

Minimal Phoenix JSON API. Requires Elixir 1.20+ and Erlang/OTP.

```sh
mix deps.get
mix phx.server
```

Visit http://localhost:4000/api/hello:

```json
{"message":"Hello, world!"}
```

All application code lives in `lib/mega_elixir.ex`; server configuration is in
`config/config.exs`. No database or frontend.

Run tests with `mix test`.

On Windows PowerShell, use `mix.bat` if execution policy blocks `mix.ps1`.
To use another port: `$env:PORT = "4001"; mix.bat phx.server`.
