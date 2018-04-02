defmodule Blog.Files do
  def get_all_posts(mock) do
    cond do
      mock -> ["post_1.md", "post_2.md"]
      true -> File.ls("posts")
    end
  end
end
