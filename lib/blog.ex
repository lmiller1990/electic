defmodule Blog do
  def start(file) do
    read_file(file)
    |> get_output_file_name
    |> parse_content  
    |> write_to_html
  end

  def get_output_file_name(%Blog.Post{filename: filename} = post) do
    name = 
      String.split(filename, "/")
      |> List.last
      |> String.split(".")
      |> List.first

    %{post | name: name}
  end

  def parse_content(%Blog.Post{raw_text: raw_text} = post) do
    case Earmark.as_html(raw_text) do
      {:ok, html_doc, []} -> %{post | content: html_doc}
      {:error, _, errs} -> errs
    end
  end

  def read_file(filename) do
    case File.read(filename) do
      {:ok, raw_text} -> %Blog.Post{raw_text: raw_text, filename: filename}
      {:error, err} -> err
    end
  end

  def write_to_html(%Blog.Post{content: content, name: name} = _post) do
    File.write("docs/posts/#{name}.html", content)
  end
end
