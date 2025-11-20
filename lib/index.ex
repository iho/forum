defmodule Forum.Index do
  require N2O ; require Logger

  # Index page is now just a redirect to categories
  # This module is kept for routing compatibility but does nothing
  def event(:init) do
    Logger.info("Index page accessed - will redirect to categories")
    []
  end

  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()
end
