defmodule Blog.Generators do
  def generate_index() do
    {:ok, files} = File.ls("posts")

    posts = for file <- files do
      %Blog.Post{link: generate_link(file), title: filepath_to_pretty_name(file)}
    end

    html = EEx.eval_file("templates/index.html.eex", [posts: posts])

    File.write("docs/index.html", html)
  end

  def generate_post_html(filepath) do
    {:ok, markup} = File.read(filepath)
    html = parse_content(markup)
    write_post_to_path(filepath, html)
  end

  def generate_link(link) do
    String.replace(link, "md", "html")
    |> String.downcase
    |> String.replace_prefix("", "posts/")
  end

  def write_post_to_path(filepath, content) do
    title = filepath_to_pretty_name(filepath)
    html = EEx.eval_file("templates/show.html.eex", [title: title, body: content])

    path = String.replace(title, " ", "_") |> String.downcase

    File.write("docs/posts/#{path}.html", html)
  end

  def filepath_to_pretty_name(filepath) do
    String.split(filepath, "/") 
    |> List.last 
    |> prettify_post_name
  end

  def parse_content(markup) do
    case Earmark.as_html(markup) do
      {:ok, html_doc, []} -> html_doc
      {:error, _, errs} -> errs
    end
  end

  def prettify_post_name(filepath) do
    String.split(filepath, ".")
    |> List.first
    |> String.replace("_", " ")
  end
end 
