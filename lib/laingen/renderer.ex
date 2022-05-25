defmodule Laingen.Renderer do
  alias Laingen.{Utils, Post, Archive}

  defp render_archive_item(item, to_dir, archive, type) when type == "post" do
    filename = Utils.set_file_ext(item["data"]["filename"], ".html")
    ctx = Map.merge(item["data"]["metadata"], %{"html"=>item["data"]["html"]})
    Utils.render_template(Utils.get_template("archive/post"), ctx)
    |> Enum.map(&File.write(to_dir <> "/" <> filename, &1, [:append]))
    %{"title"=> item["data"]["metadata"]["Title"], "url"=>"/archive/" <> archive <> "/" <> filename}
  end


  defp render_archive_item(item, to_dir, archive, type) when type == "file" do
    path = item["data"]["path"]
    filename = item["data"]["filename"]
    File.cp!(path, to_dir <> "/" <> filename)
    %{"title"=>filename, "url"=>"/archive/" <> archive <> "/" <> filename}
  end

  defp render_archive(name, items) do
    out_dir = "output/archive/" <> name
    File.mkdir_p!(out_dir)
    processed_items = (items |> Enum.map(fn item -> render_archive_item(item, out_dir, name, item["type"]) end))
    template = Utils.get_template("archive/content")
    Utils.render_template(template, %{"items"=> processed_items, "name"=>name})
    |> Enum.map(&File.write(out_dir <> "/index.html", &1, [:append]))
    name
  end
  def render_archives(path) do
    Archive.get_archives(path)
    |> Enum.map(fn result -> render_archive(result["archive"], result["items"]) end)
  end
  def render_archive_index(names) do
    out_path = "output/archive/index.html"
    template = Utils.get_template("archive/index")
    Utils.render_template(template, %{"names"=>names})
    |> Enum.map(&File.write(out_path, &1, [:append]))
  end
  defp render_post(post, out_dir) do
    base_url = "/blog/posts"
    {:ok, metadata, html} = Post.get_post(post)
    if metadata["Draft"] == false do
      url = base_url <> "/" <> Utils.set_file_ext(post, ".html")
      metadata = Map.merge(metadata, %{"Date"=>(metadata["Date"]|> Date.from_iso8601!), "url"=>url})
      ctx = Map.merge(metadata, %{"html"=>html})
      template = Utils.get_template("blog/post")
      filename = Utils.set_file_ext(post, ".html")
      Utils.render_template(template, ctx)
      |> Enum.map(fn text -> File.write(out_dir <> "/" <> filename, text, [:append]) end)
      Map.merge(metadata, %{"Html" => html})
    else
      nil
    end
  end

  def render_posts() do
    out_dir = "output/blog/posts"
    File.mkdir_p(out_dir)
    File.ls!("posts")
    |> Enum.filter(fn x -> Post.is_post(x) end)
    |> Enum.map(fn x -> render_post(x, out_dir) end)
    |> Enum.filter(fn x -> x != nil end)
    |> Enum.sort(fn p1, p2 -> Date.diff(p1["Date"], p2["Date"]) > 0 end)
  end

  def render_blog_page(posts, page_num, tags, out_dir, pages) do
    out_path = out_dir <> "/" <> Integer.to_string(page_num)
    File.mkdir_p(out_path)
    template = Utils.get_template("blog/blog")
    ctx = %{"posts"=>posts, "page"=>page_num, "tags"=>tags, "pages"=>pages}
    Utils.render_template(template, ctx)
    |> Enum.map(&File.write(out_path <> "/index.html", &1, [:append]))

  end

  def render_blog_index(tags, posts) do
    out_dir = "output/blog"
    File.mkdir_p(out_dir)
    page_size = 10
    pages = Float.ceil(Enum.count(posts) / page_size)
    File.ln_s("1/index.html", out_dir <> "/index.html")
    posts
    |> Enum.chunk_every(page_size)
    |> Enum.with_index(fn p, i -> render_blog_page(p, i + 1, tags, out_dir, pages) end)
  end

  def render_tag_page(tag, posts, page_num, out_dir, pages) do
    out_path = out_dir <> "/" <> Integer.to_string(page_num)
    File.mkdir_p(out_path)
    template = Utils.get_template("blog/tag")
    ctx = %{"tag"=>tag, "posts"=>posts, "page"=>page_num, "pages"=>pages}
    Utils.render_template(template, ctx)
    |> Enum.map(fn text -> File.write(out_path <> "/index.html", text, [:append]) end)
  end

  def render_tag_index(tag, posts) do
    out_dir = "output/blog/tags/" <> tag
    File.mkdir_p(out_dir)
    page_size = 10
    pages = Float.ceil(Enum.count(posts) / page_size)
    File.ln_s("1/index.html", out_dir <> "/index.html")
    posts
    |> Enum.chunk_every(page_size)
    |> Enum.with_index(fn p, i -> render_tag_page(tag, p, i+1, out_dir, pages) end)
    tag
  end
  def render_and_collect_tags(posts) do
    posts
    |> Enum.map(&Post.to_tag_map(&1))
    |> Enum.reduce(fn tm1, tm2 -> Map.merge(tm1, tm2, fn _, v1, v2 -> v2 ++ v1 end) end)
    |> Enum.map(fn {k, v} -> render_tag_index(k, v) end)
    |> Enum.sort
  end

  def render_project_page() do
    project_file = "projects.csv"
    projects = Utils.get_projects(project_file)
    out_dir = "output/projects"
    File.mkdir_p(out_dir)
    template = Utils.get_template("projects/projects")
    Utils.render_template(template, %{"projects"=>projects})
    |> Enum.map(fn text -> File.write(out_dir <> "/index.html", text, [:append]) end)
    projects
  end

  def render_with_context(template_name, context, target_file) do
    out_dir = Utils.parent_dir(target_file)
    File.mkdir_p(out_dir)
    rendered_text = Utils.get_template(template_name)
    |> Utils.render_template(context)
    File.write(target_file, rendered_text, [:append])
  end



  def render_all() do
    File.mkdir_p("output")
    posts = render_posts()
    posts
    |> render_and_collect_tags
    |> render_blog_index(posts)
    projects = render_project_page()

    render_archives("archive")
    |> render_archive_index

    if File.dir?("archive/hidden"), do: render_archives("archive/hidden")


    render_with_context("index", %{"projects"=>Enum.take(projects, 4), "posts"=>Enum.take(posts, 4)}, "output/index.html")
    render_with_context("rss", %{"posts"=>posts}, "output/rss.xml")

    donate_body = File.read!("templates/donate/donate.html")
    render_with_context("_base", %{"title"=>"Donate", "body"=>donate_body}, "output/donate/index.html")

    about_body = "<section class='centered'>\n" <> Utils.load_markdown("posts/about/en.md") <> "\n</section>"
    render_with_context("_base", %{"title"=>"About shinji.rocks", "body"=>about_body}, "output/about/index.html")
  end


end
