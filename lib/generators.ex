defmodule Electic.Generators do
  alias Electic.Utils, as: Utils

  def generate_index() do
    {:ok, files} = File.ls("posts")
    files = files |> Utils.remove_drafts
    

    posts = for file <- files do
      %Electic.Post{
        link: Utils.filename_to_link(file), 
        title: Utils.filepath_to_pretty_name(file)
      }
    end

    html = EEx.eval_file("templates/index.html.eex", [posts: posts])

    File.write("docs/index.html", html)
  end

  def generate_all_posts_html() do
    {:ok, files} = File.ls("posts")
    for file <- files do
      generate_post_html("posts/#{file}")
    end
  end

  def generate_post_html(filepath) do
    {:ok, markup} = File.read(filepath)
    html = parse_markup_to_html(markup)
    write_post_to_path(filepath, html)
  end

  def write_post_to_path(filepath, content) do
    title = Utils.filepath_to_pretty_name(filepath)
    html = EEx.eval_file("templates/show.html.eex", [title: title, body: content])

    path = String.replace(title, " ", "_") |> String.downcase

    File.write("docs/posts/#{path}.html", html)
  end

  def parse_markup_to_html(markup) do
    case Earmark.as_html(markup, %Earmark.Options{code_class_prefix: "lang- language-"}) do
      {:ok, html_doc, []} -> html_doc
      {:error, _, errs} -> errs
    end
  end
end 
