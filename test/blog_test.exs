defmodule BlogTest do
  use ExUnit.Case
  doctest Blog

  test "parses the title" do
    title = %Blog.Post{filename: "posts/test.md"} |> Blog.parse_title

    assert title == "test"
  end
end
