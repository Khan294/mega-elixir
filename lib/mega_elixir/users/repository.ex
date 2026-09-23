defmodule MegaElixir.Users.Repository do
  @moduledoc "In-memory data layer for users, backed by an Agent."

  use Agent

  alias MegaElixir.Users.User

  def start_link(_opts) do
    Agent.start_link(fn -> %{next_id: 1, users: %{}} end, name: __MODULE__)
  end

  def list do
    Agent.get(__MODULE__, fn s -> s.users |> Map.values() |> Enum.sort_by(& &1.id) end)
  end

  def get(id) do
    with {:ok, id} <- parse_id(id) do
      Agent.get(__MODULE__, fn s ->
        case Map.fetch(s.users, id) do
          {:ok, user} -> {:ok, user}
          :error -> {:error, :not_found}
        end
      end)
    end
  end

  def create(attrs) do
    Agent.get_and_update(__MODULE__, fn s ->
      user =
        struct!(User, Map.merge(attrs, %{id: s.next_id, inserted_at: now(), updated_at: now()}))

      {{:ok, user}, %{s | next_id: s.next_id + 1, users: Map.put(s.users, user.id, user)}}
    end)
  end

  def update(id, attrs) do
    with {:ok, id} <- parse_id(id) do
      Agent.get_and_update(__MODULE__, fn s ->
        case Map.fetch(s.users, id) do
          :error ->
            {{:error, :not_found}, s}

          {:ok, user} ->
            updated = struct!(user, Map.put(attrs, :updated_at, now()))
            {{:ok, updated}, %{s | users: Map.put(s.users, id, updated)}}
        end
      end)
    end
  end

  def delete(id) do
    with {:ok, id} <- parse_id(id) do
      Agent.get_and_update(__MODULE__, fn s ->
        case Map.pop(s.users, id) do
          {nil, _} -> {{:error, :not_found}, s}
          {user, users} -> {{:ok, user}, %{s | users: users}}
        end
      end)
    end
  end

  def reset do
    Agent.update(__MODULE__, fn _ -> %{next_id: 1, users: %{}} end)
  end

  defp parse_id(id) when is_integer(id) and id > 0, do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} when n > 0 -> {:ok, n}
      _ -> {:error, :not_found}
    end
  end

  defp parse_id(_), do: {:error, :not_found}

  defp now, do: DateTime.utc_now() |> DateTime.truncate(:second)
end
