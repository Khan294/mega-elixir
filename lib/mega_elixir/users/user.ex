defmodule MegaElixir.Users.User do
  @moduledoc "A user, independent of persistence."

  @enforce_keys [:id, :name, :email, :inserted_at, :updated_at]
  defstruct [:id, :name, :email, :inserted_at, :updated_at]
end
