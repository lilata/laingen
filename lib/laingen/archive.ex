defmodule Laingen.Archive do
  alias Laingen.Post
  def get_archives(dir) do
    File.ls!(dir)
    |> Enum.filter(fn d -> d != "hidden" and File.dir?(dir <> "/" <> d) end)
    |> Enum.map(fn a -> %{"archive"=>a, "items"=>get_items(a, dir)} end)
  end
  def get_items(archive, dir) do
    File.ls!(dir <> "/" <> archive)
    |> Enum.filter(fn f -> not File.dir?(f) end)
    |> Enum.map(&item_data(&1, archive, dir))
  end

  def item_data(item, archive, dir) do
    if String.ends_with?(item, ".md") do
      {:ok, metadata, html} = Post.get_post(dir <> "/" <> archive <> "/" <> item)
      %{"data"=>%{"metadata"=>metadata, "html"=>html, "filename"=>item}, "type"=>"post"}
    else
      %{"data"=>%{"path"=>dir <> "/" <> archive <> "/" <> item, "filename"=>item}, "type"=>"file"}
    end
  end
end
