defmodule MegaElixir.Users do
  @moduledoc "The business context for managing users."

  alias MegaElixir.Users.Repository

  @email_pattern ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  def list_users, do: Repository.list()
  def get_user(id), do: Repository.fetch(id)
  def delete_user(id), do: Repository.delete(id)

  def create_user(attrs) when is_map(attrs) do
    with {:ok, user_attrs} <- validate(attrs, [:name, :email]) do
      Repository.create(user_attrs)
    end
  end

  def update_user(id, attrs) when is_map(attrs) do
    with {:ok, user} <- Repository.fetch(id),
         {:ok, user_attrs} <- validate(attrs, [], user) do
      Repository.update(id, user_attrs)
    end
  end

  defp validate(attrs, required, current \\ nil) do
    name = value(attrs, "name", current && current.name)
    email = value(attrs, "email", current && current.email)

    errors =
      %{}
      |> require_field(:name, name, required)
      |> require_field(:email, email, required)
      |> validate_name(name)
      |> validate_email(email)

    if errors == %{} do
      {:ok, %{name: String.trim(name), email: email |> String.trim() |> String.downcase()}}
    else
      {:error, :validation, errors}
    end
  end

  defp value(attrs, key, default),
    do: Map.get(attrs, key, Map.get(attrs, String.to_atom(key), default))

  defp require_field(errors, field, value, required) do
    if field in required and blank?(value),
      do: Map.put(errors, field, ["can't be blank"]),
      else: errors
  end

  defp validate_name(errors, value) do
    cond do
      blank?(value) -> errors
      not is_binary(value) -> Map.put(errors, :name, ["must be a string"])
      String.length(String.trim(value)) > 100 -> Map.put(errors, :name, ["is too long"])
      true -> errors
    end
  end

  defp validate_email(errors, value) do
    cond do
      blank?(value) ->
        errors

      not is_binary(value) ->
        Map.put(errors, :email, ["must be a string"])

      not Regex.match?(@email_pattern, String.trim(value)) ->
        Map.put(errors, :email, ["has invalid format"])

      true ->
        errors
    end
  end

  defp blank?(value) when is_binary(value), do: String.trim(value) == ""
  defp blank?(value), do: is_nil(value)
end
