defmodule MegaElixirTest do
  use ExUnit.Case
  doctest MegaElixir

  test "greets the world" do
    assert MegaElixir.hello() == :world
  end
end
