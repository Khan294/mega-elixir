defmodule MegaElixirWeb.UserJSON do
  alias MegaElixir.Users.User

  def data(%User{} = user) do
    %{
      id: user.id,
      name: user.name,
      email: user.email,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
