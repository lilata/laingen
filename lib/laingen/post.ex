defmodule Laingen.Post do
  alias Laingen.Utils
  def to_tag_map(post) do
    post["Tags"]
    |> Map.new(fn t -> {t, [post]} end)
  end

  def is_post(relpath) do
    (not File.dir?("posts/" <> relpath)) and String.ends_with?(relpath, ".md")
  end

  def get_post(path) do
    path = Utils.set_file_ext(path, ".md")
    real_path = if File.exists?(path), do: path, else: "posts/" <> path
    {:ok, metadata, markdown} = YamlFrontMatter.parse_file(real_path)
    {:ok, metadata, Earmark.as_html!(markdown)}
  end

end

