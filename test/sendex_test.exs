defmodule SendexTest do
  use ExUnit.Case
  doctest Sendex

  test "greets the world" do
    assert Sendex.hello() == :world
  end
end
