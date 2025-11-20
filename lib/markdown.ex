defmodule Forum.Markdown do
  @moduledoc """
  Safe markdown rendering with XSS protection.
  Converts markdown to HTML and sanitizes the output.
  """

  @doc """
  Converts markdown text to safe HTML.
  Returns the HTML as a string that can be used in :nitro elements.
  """
  def to_html(markdown_text) when is_binary(markdown_text) do
    markdown_text
    |> Earmark.as_html!()
    |> HtmlSanitizeEx.markdown_html()
  end

  def to_html(_), do: ""
end
