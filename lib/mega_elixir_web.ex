defmodule MegaElixirWeb do
  def controller do
    quote do
      use Phoenix.Controller, formats: [:json]

      import Plug.Conn
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: MegaElixirWeb.Endpoint,
        router: MegaElixirWeb.Router
    end
  end

  defmacro __using__(which) when is_atom(which), do: apply(__MODULE__, which, [])
end
