defmodule MegaElixirWeb.Router do
  use MegaElixirWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", MegaElixirWeb do
    pipe_through(:api)

    resources("/users", UserController, except: [:new, :edit])
  end
end
