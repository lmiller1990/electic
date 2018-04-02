defmodule Blog.Generators do
  def index() do
    {:ok, files} = Blog.Files.get_all_posts(false)
    
    create_links_to_each_file(files)
    |> Enum.join("<br>")
    |> write_to_index
  end

  def write_to_index(content) do
    File.write("docs/index.html", content)
  end

  def create_links_to_each_file(files) do
    for file <- files do
      create_link(file)
    end
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

    "<a href=\"posts/#{href}\">#{pretty_name}</a>"
  end

  def prettify_post_name(filename) do
    String.split(filename, ".")
    |> List.first
    |> String.replace("_", " ")
  end
end 
