defmodule MegaElixir.User do
  @moduledoc "A user account, kept independent of its current persistence mechanism."

  @enforce_keys [:id, :name, :email, :inserted_at, :updated_at]
  defstruct [:id, :name, :email, :inserted_at, :updated_at]

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          email: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }
end
