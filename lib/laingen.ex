defmodule Laingen do
  @moduledoc """
  Documentation for `Laingen`.
  """
  alias Laingen.{Utils, Renderer}
  @doc """
  Clean, render pages and copy static files.
  ## Examples

      iex> Laingen.render()
  """
  def render() do
    Utils.clean()
    Renderer.render_all()
    Utils.copy_static()
    :ok
  end
  


end
