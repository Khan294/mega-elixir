defmodule MegaElixir.Users.Repository do
  @moduledoc "An in-memory user repository owned by the application supervision tree."

  use Agent

  alias MegaElixir.User

  def start_link(_opts),
    do: Agent.start_link(fn -> %{next_id: 1, users: %{}} end, name: __MODULE__)

  def list do
    Agent.get(__MODULE__, fn state -> state.users |> Map.values() |> Enum.sort_by(& &1.id) end)
  end

  def fetch(id) do
    case parse_id(id) do
      {:ok, id} -> Agent.get(__MODULE__, &fetch_from_state(&1, id))
      :error -> {:error, :not_found}
    end
  end

  def create(attrs) do
    Agent.get_and_update(__MODULE__, fn state ->
      if email_taken?(state, attrs.email) do
        {{:error, :validation, %{email: ["has already been taken"]}}, state}
      else
        now = DateTime.utc_now() |> DateTime.truncate(:second)

        user =
          struct!(User, Map.merge(attrs, %{id: state.next_id, inserted_at: now, updated_at: now}))

        {{:ok, user},
         %{state | next_id: state.next_id + 1, users: Map.put(state.users, user.id, user)}}
      end
    end)
  end

  def update(id, attrs) do
    with {:ok, id} <- parse_id(id) do
      Agent.get_and_update(__MODULE__, fn state ->
        case Map.fetch(state.users, id) do
          :error ->
            {{:error, :not_found}, state}

          {:ok, user} ->
            if email_taken?(state, attrs.email, id) do
              {{:error, :validation, %{email: ["has already been taken"]}}, state}
            else
              updated =
                struct!(
                  user,
                  Map.put(attrs, :updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
                )

              {{:ok, updated}, %{state | users: Map.put(state.users, id, updated)}}
            end
        end
      end)
    else
      :error -> {:error, :not_found}
    end
  end

  def delete(id) do
    with {:ok, id} <- parse_id(id) do
      Agent.get_and_update(__MODULE__, fn state ->
        case Map.pop(state.users, id) do
          {nil, _users} -> {{:error, :not_found}, state}
          {user, users} -> {{:ok, user}, %{state | users: users}}
        end
      end)
    else
      :error -> {:error, :not_found}
    end
  end

  defp parse_id(id) when is_integer(id) and id > 0, do: {:ok, id}

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {parsed, ""} when parsed > 0 -> {:ok, parsed}
      _other -> :error
    end
  end

  defp parse_id(_id), do: :error
  defp fetch_from_state(state, id), do: Map.fetch(state.users, id) |> normalize_fetch()
  defp normalize_fetch({:ok, user}), do: {:ok, user}
  defp normalize_fetch(:error), do: {:error, :not_found}

  defp email_taken?(state, email, except_id \\ nil) do
    Enum.any?(state.users, fn {id, user} -> id != except_id and user.email == email end)
  end
end
