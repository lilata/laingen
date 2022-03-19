defmodule Mix.Tasks.Laingen.Render do
  @moduledoc "The task to render all pages and copy static files"
  use Mix.Task

  @shortdoc "Calls Laingen.render"
  def run(_) do
    Mix.Task.run("app.start")
    Laingen.render()
  end
end
