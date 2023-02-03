defmodule FrankyBotTest do
  use ExUnit.Case
  doctest FrankyBot

  test "greets the world" do
    assert FrankyBot.hello() == :world
  end
end
