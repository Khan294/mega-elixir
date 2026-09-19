defmodule MegaElixir.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: MegaElixir.PubSub},
      MegaElixir.Users.Repository,
      MegaElixirWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MegaElixir.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    MegaElixirWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
