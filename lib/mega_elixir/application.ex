defmodule MegaElixir.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MegaElixir.Users.Repository,
      MegaElixirWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MegaElixir.Supervisor)
  end
end
