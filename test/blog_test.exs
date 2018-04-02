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


  test "prettifies filename" do
    pretty_name = Blog.Generators.prettify_post_name("Testing_in_Elixir.md")

    assert pretty_name == "Testing in Elixir"
  end

  test "creates link to post" do
    filename = "Testing_in_Elixir.md"

    href = Blog.Generators.create_link(filename)

    assert href == "<a href=\"testing_in_elixir.html\">Testing in Elixir</a>"
  end

  test "creates href" do
    href = Blog.Generators.create_href("Testing in Elixir", "testing_in_elixir.md")

    assert href == "<a href=\"testing_in_elixir.html\">Testing in Elixir</a>"

  end
end
