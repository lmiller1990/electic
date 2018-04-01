defmodule BlogTest do
  use ExUnit.Case
  doctest Blog

  test "extracts output filename" do
    %Blog.Post{name: name} = 
      %Blog.Post{filename: "posts/test.md"} 
      |> Blog.get_output_file_name

    assert name == "test"
  end

  test "passes markup" do
    %Blog.Post{content: content} =
      %Blog.Post{raw_text: "# test"}
      |> Blog.parse_content

    assert content == "<h1>test</h1>"
  end
end
