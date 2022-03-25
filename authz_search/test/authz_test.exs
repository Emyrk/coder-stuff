defmodule AuthzTest do
  use ExUnit.Case
  doctest Authz

  test "greets the world" do
    assert Authz.hello() == :world
  end
end
