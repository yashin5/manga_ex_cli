defmodule MangaExCliTest do
  use ExUnit.Case
  doctest MangaExCli

  test "greets the world" do
    assert MangaExCli.hello() == :world
  end
end
