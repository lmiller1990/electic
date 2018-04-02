defmodule Blog.Generators do
  def index() do
    {:ok, files} = Blog.Files.get_all_posts(false)
    files 
  end

  def create_link(filename) do
    filename
    |> prettify_post_name
    |> create_href(filename)
  end

  def create_href(pretty_name, filename) do
    href = 
      String.replace(filename, "md", "html")
      |> String.downcase

    "<a href=\"#{href}\">#{pretty_name}</a>"
  end

  def prettify_post_name(filename) do
    String.split(filename, ".")
    |> List.first
    |> String.replace("_", " ")
  end
end 
