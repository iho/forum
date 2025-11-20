defmodule Forum.Thread do
  require NITRO ; require KVS ; require N2O ; require Logger

  def event(:init) do
    # Setup button to load thread - will be auto-clicked by client JS
    :nitro.update(:__init_btn__, NITRO.button(
      id: :__init_btn__,
      body: "",
      postback: :load,
      source: [:__thread_id__],
      style: "display:none;"
    ))
    []
  end

  def event(:load) do
    thread_id = :nitro.to_binary(:nitro.q(:__thread_id__))
    Logger.info("Loading thread: #{inspect(thread_id)}")

    if thread_id != "" do
      :n2o.session(:room, thread_id)
      load_thread_data(thread_id)
    else
      :nitro.update(:threadTitle, NITRO.h1(id: :threadTitle, body: "No thread ID provided"))
    end
  end

  def event(:reply) do
    thread_id = :n2o.session(:room)
    user_id = :n2o.session(:user_id)

    # Get author ID from session, default to "Anonymous"
    author_id = if user_id && user_id != [] && user_id != "" do
      user_id
    else
      "Anonymous"
    end

    message = :nitro.to_binary(:nitro.q(:replyMessage))

    if message != "" do
      post_id = :kvs.seq(:post, 1) |> :erlang.list_to_binary()
      post = {:post, post_id, thread_id, author_id, message, :os.system_time(:seconds)}
      :kvs.put(post)

      # Update thread reply count
      case :kvs.get(:thread, thread_id) do
        {:ok, {:thread, id, cat_id, title, author, content, ts, count}} ->
          updated_thread = {:thread, id, cat_id, title, author, content, ts, count + 1}
          :kvs.put(updated_thread)
        _ -> :ok
      end

      # Update UI
      add_reply_to_ui(post)
      :nitro.wire("document.getElementById('replyMessage').value = '';")
    end
  end

  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()

  defp load_thread_data(thread_id) do
    # Load thread details
    case :kvs.get(:thread, thread_id) do
      # New thread structure
      {:ok, {:thread, _id, _category_id, title, author_id, content, _timestamp, _reply_count}} ->
        author_name = case :kvs.get(:forum_user, author_id) do
          {:ok, {:forum_user, _, name, _, _, _}} -> name
          _ when is_binary(author_id) -> author_id
          _ -> "Unknown"
        end
        :nitro.update(:threadTitle, NITRO.h1(id: :threadTitle, body: title))
        html_content = Forum.Markdown.to_html(content)
        full_html = "<h4>#{author_name}</h4>" <> html_content
        :nitro.update(:originalPost, NITRO.panel(class: :post, body: full_html))
      # Old thread structure
      {:ok, {:thread, _id, title, author, content, _timestamp}} ->
        :nitro.update(:threadTitle, NITRO.h1(id: :threadTitle, body: title))
        html_content = Forum.Markdown.to_html(content)
        full_html = "<h4>#{author}</h4>" <> html_content
        :nitro.update(:originalPost, NITRO.panel(class: :post, body: full_html))
      _ ->
        :nitro.update(:threadTitle, NITRO.h1(id: :threadTitle, body: "Thread not found"))
    end

    # Load replies
    load_replies(thread_id)

    # Setup reply button
    :nitro.update(:replyButton, NITRO.button(id: :replyButton, body: "Post Reply", postback: :reply, source: [:replyMessage]))
  end

  defp load_replies(thread_id) do
    # Load all posts and filter by thread_id
    posts = :kvs.all(:post)
    Enum.each(posts, fn post ->
      case post do
        {:post, _, tid, _, _, _} when tid == thread_id -> add_reply_to_ui(post)
        {:post, _, tid, _, _} when tid == thread_id -> add_reply_to_ui(post)  # Old format
        _ -> :ok
      end
    end)
  end

  # New post structure
  defp add_reply_to_ui({:post, _, _, author_id, content, _}) do
    author_name = case :kvs.get(:forum_user, author_id) do
      {:ok, {:forum_user, _, name, _, _, _}} -> name
      _ when is_binary(author_id) -> author_id
      _ -> "Unknown"
    end

    html_content = Forum.Markdown.to_html(content)
    full_html = "<span class='author'>#{author_name}: </span>" <> html_content <> "<br/>"
    :nitro.insert_bottom(:replies, NITRO.panel(class: :reply, body: full_html))
  end

  # Old post structure (for backwards compatibility)
  defp add_reply_to_ui({:post, _, author, content, _}) do
    html_content = Forum.Markdown.to_html(content)
    full_html = "<span class='author'>#{author}: </span>" <> html_content <> "<br/>"
    :nitro.insert_bottom(:replies, NITRO.panel(class: :reply, body: full_html))
  end
end
