defmodule Laingen.Utils do
  def get_projects(csv) do
    sep = "|"
    File.read!(csv)
    |> String.split("\n")
    |> Enum.filter(fn d -> String.length(d) > 1 end)
    |> Enum.map(&String.split(&1, sep))
    |> make_project_map
  end

  def make_project_map(list) do
    {keys, data} = List.pop_at(list, 0)
    data
    |> Enum.map(&process_project(&1, keys))
  end

  def process_project(list, keys) do
    list
    |> Enum.map(&String.trim(&1))
    |> Enum.with_index(fn e, i -> {Enum.at(keys, i), e} end)
    |> Map.new
  end

  def get_template(relpath) do
    relpath = if String.ends_with?(relpath, ".liquid"), do: relpath, else: relpath <> ".liquid"
    File.read!("templates/" <> relpath)
    |> Solid.parse!
  end

  def load_markdown(file) do
    Earmark.as_html!(File.read!(file))
  end



  def render_template(template, vars) do
    fs = Solid.LocalFileSystem.new(File.cwd! <> "/templates")
    default_vars = %{"base_url"=>"https://shinji.rocks", "alois_base_url"=> "https://alois.shinji.rocks"}
    vars = Map.merge(vars, default_vars)
    Solid.render(template, vars, [file_system: {Solid.LocalFileSystem, fs}])
  end

  def copy_static() do
    File.mkdir_p("output")
    File.cp_r("static/", "output")
  end

  def clean() do
    File.rm_rf("output")
  end

  def set_file_ext(filename, ext) do
    if String.ends_with?(filename, ext) do
      filename
    else
      base_name = String.reverse(filename)
      |> String.split(".", parts: 2)
      |> Enum.at(-1)
      |> String.reverse
      base_name <> ext
    end
  end

  def get_file_basename(filename) do
    String.reverse(filename)
    |> String.split("/", parts: 2)
    |> Enum.at(0)
    |> String.reverse
  end


  def parent_dir(path) do
    String.reverse(path)
    |> String.split("/", parts: 2)
    |> Enum.at(-1)
    |> String.reverse
  end
end
