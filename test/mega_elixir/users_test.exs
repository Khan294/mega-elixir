defmodule MegaElixir.UsersTest do
  use ExUnit.Case, async: false

  alias MegaElixir.Users
  alias MegaElixir.Users.Repository

  setup do
    Repository.reset()
    :ok
  end

  test "creates and lists users" do
    assert {:ok, user} = Users.create_user(%{"name" => "Ada", "email" => "ada@example.com"})
    assert user.id == 1
    assert user.name == "Ada"

    assert [%{email: "ada@example.com"}] = Users.list_users()
  end

  test "rejects an invalid email" do
    assert {:error, errors} = Users.create_user(%{"name" => "Ada", "email" => "not-an-email"})
    assert errors.email == "has invalid format"
  end

  test "requires name and email" do
    assert {:error, errors} = Users.create_user(%{"email" => "ada@example.com"})
    assert errors.name == "can't be blank"
  end

  test "gets, updates, and deletes a user" do
    {:ok, user} = Users.create_user(%{"name" => "Ada", "email" => "ada@example.com"})

    assert {:ok, ^user} = Users.get_user(user.id)

    assert {:ok, updated} =
             Users.update_user(user.id, %{"name" => "Grace", "email" => "grace@example.com"})

    assert updated.name == "Grace"

    assert {:ok, _} = Users.delete_user(user.id)
    assert {:error, :not_found} = Users.get_user(user.id)
  end
end
