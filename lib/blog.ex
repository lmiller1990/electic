defmodule Blog do
  def start() do
    read_file("posts/tester.md")
    |> parse  
    |> write_to_html("testerr")
  end

  def parse(file) do
    case Earmark.as_html(file) do
      {:ok, html_doc, []} -> html_doc 
      {:error, _, errs} -> errs
    end
  end

  def read_file(filename) do
    case File.read(filename) do
      {:ok, file} -> file 
      {:error, err} -> err
    end
  end

  def write_to_html(html, filename) do
    File.write("docs/posts/#{filename}.html", html)
  end
end
