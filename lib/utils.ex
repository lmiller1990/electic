defmodule Electic.Utils do
  @mock Application.get_env(:electic, :mock)

  @moduledoc """
  Some utils for extracing information from filepaths.
  """

  @doc """
  Delete all existing posts.

  """
  def delete_all_posts() do
    {:ok, files} = File.ls("posts")

    for file <- files do
      delete_file("posts/#{file}")
    end
  end

  def delete_all_html_files() do
    {:ok, files} = File.ls("docs/posts")

    for file <- files do
      delete_file("docs/posts/#{file}")
    end

    delete_file("docs/index.html")
    delete_file("docs/index.css")
  end

  def delete_file(path) do
    File.rm(path)
  end

  @doc """
  Loads a mock.

  ## Examples
      iex> Electic.Utils.mock()
      "mock"
  """
  def mock() do
    @mock
  end

  @doc """
  Parses a filepath to a nicely formatted string.

  ## Examples
      iex> Electic.Utils.filename_to_pretty_name("My_post.md")
      "My post"

  """
  def filename_to_pretty_name(filename) do
    String.split(filename, ".")
    |> List.first
    |> String.replace("_", " ")
  end

  @doc """
  Parse a filename to a link.

  ## Examples

      iex> Electic.Utils.filename_to_link("My_post.md")
      "posts/my_post.html"
  """
  def filename_to_link(link) do
    String.replace(link, "md", "html")
    |> String.downcase
    |> String.replace_prefix("", "posts/")
  end


  @doc """
  Parse a file path to a nicely formatted string.

  ## Examples

      iex> Electic.Utils.filepath_to_pretty_name("some/posts/My_post.md")
      "My post"
  """
  def filepath_to_pretty_name(filepath) do
    String.split(filepath, "/") 
    |> List.last 
    |> Electic.Utils.filename_to_pretty_name
  end
end
