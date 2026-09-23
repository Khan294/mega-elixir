defmodule MegaElixir.Users do
  @moduledoc "Users service: validates input and delegates persistence to the repository."

  alias MegaElixir.Users.Repository

  @email ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  def list_users, do: Repository.list()

  def get_user(id), do: Repository.get(id)

  def delete_user(id), do: Repository.delete(id)

  def create_user(attrs) when is_map(attrs) do
    with {:ok, params} <- validate(attrs) do
      Repository.create(params)
    end
  end

  def update_user(id, attrs) when is_map(attrs) do
    with {:ok, params} <- validate(attrs) do
      Repository.update(id, params)
    end
  end

  defp validate(attrs) do
    name = attrs["name"]
    email = attrs["email"]

    errors =
      %{}
      |> put_error(:name, "can't be blank", blank?(name))
      |> put_error(:email, "can't be blank", blank?(email))
      |> put_error(:email, "has invalid format", present?(email) and not Regex.match?(@email, String.trim(email)))

    if map_size(errors) == 0 do
      {:ok, %{name: String.trim(name), email: email |> String.trim() |> String.downcase()}}
    else
      {:error, errors}
    end
  end

  defp put_error(errors, _field, _msg, false), do: errors
  defp put_error(errors, field, msg, true), do: Map.put(errors, field, msg)

  defp blank?(nil), do: true
  defp blank?(str), do: String.trim(str) == ""
  defp present?(str), do: not blank?(str)
end
