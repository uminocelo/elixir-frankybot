defmodule FrankyTest do
  use ExUnit.Case
  doctest Franky

  test "greets the world" do
    assert Franky.hello() == :world
  end
end
