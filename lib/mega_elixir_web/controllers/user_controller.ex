defmodule MegaElixirWeb.UserController do
  use MegaElixirWeb, :controller

  alias MegaElixir.Users
  alias MegaElixirWeb.UserJSON

  def index(conn, _params) do
    json(conn, %{data: Enum.map(Users.list_users(), &UserJSON.data/1)})
  end

  def show(conn, %{"id" => id}) do
    case Users.get_user(id) do
      {:ok, user} -> json(conn, %{data: UserJSON.data(user)})
      {:error, :not_found} -> not_found(conn)
    end
  end

  def create(conn, params) do
    with {:ok, attrs} <- user_params(params),
         {:ok, user} <- Users.create_user(attrs) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", ~p"/api/users/#{user.id}")
      |> json(%{data: UserJSON.data(user)})
    else
      {:error, :validation, errors} -> validation_error(conn, errors)
    end
  end

  def update(conn, %{"id" => id} = params) do
    with {:ok, attrs} <- user_params(params),
         {:ok, user} <- Users.update_user(id, attrs) do
      json(conn, %{data: UserJSON.data(user)})
    else
      {:error, :not_found} -> not_found(conn)
      {:error, :validation, errors} -> validation_error(conn, errors)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Users.delete_user(id) do
      {:ok, _user} -> send_resp(conn, :no_content, "")
      {:error, :not_found} -> not_found(conn)
    end
  end

  defp user_params(%{"user" => attrs}) when is_map(attrs), do: {:ok, attrs}
  defp user_params(_params), do: {:error, :validation, %{user: ["is required"]}}

  defp validation_error(conn, errors) do
    conn |> put_status(:unprocessable_entity) |> json(%{errors: errors})
  end

  defp not_found(conn) do
    conn |> put_status(:not_found) |> json(%{errors: %{detail: "User not found"}})
  end
end
