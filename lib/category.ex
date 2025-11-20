defmodule Forum.Category do
  require NITRO ; require KVS ; require N2O ; require Logger

  @per_page 10

  def event(:init) do
    # Setup button to load category - will be auto-clicked by client JS
    :nitro.update(:__init_btn__, NITRO.button(
      id: :__init_btn__,
      body: "",
      postback: :load,
      source: [:__category_id__],
      style: "display:none;"
    ))
    []
  end

  def event(:load) do
    category_id = :nitro.to_binary(:nitro.q(:__category_id__))
    Logger.info("Loading category: #{inspect(category_id)}")

    if category_id != "" do
      :n2o.session(:room, category_id)
      load_category_data(category_id)
    else
      :nitro.update(:categoryTitle, NITRO.h1(id: :categoryTitle, body: "Category not found"))
    end
  end

  def event({:page, page_num}) do
    category_id = :n2o.session(:room)
    setup_pagination(category_id, page_num)
  end

  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()

  defp load_category_data(category_id) do
    case :kvs.get(:category, category_id) do
      {:ok, {:category, _id, name, description, thread_count}} ->
        :nitro.update(:categoryTitle, NITRO.h1(id: :categoryTitle, body: name))
        :nitro.update(:categoryDescription, NITRO.p(id: :categoryDescription, body: description))
        :nitro.update(:threadCount, NITRO.span(id: :threadCount, body: "#{thread_count} threads"))

        # Load threads for this category
        setup_pagination(category_id, 1)

      _ ->
        :nitro.update(:categoryTitle, NITRO.h1(id: :categoryTitle, body: "Category not found"))
    end
  end

  defp setup_pagination(category_id, page_num) do
    # Get all threads and filter by category
    all_threads = :kvs.all(:thread)
    category_threads = Enum.filter(all_threads, fn thread ->
      case thread do
        {:thread, _, cat_id, _, _, _, _, _} -> cat_id == category_id
        {:thread, _, _, _, _, _} -> false  # Old threads without category
      end
    end)
    |> Enum.reverse()  # Newest first

    total_threads = length(category_threads)

    # Clear threads list
    :nitro.clear(:threadsList)

    if total_threads == 0 do
      # Show "no threads" message
      :nitro.update(:threadsList, NITRO.p(
        body: "No threads in this category yet. Be the first to create one!",
        style: "color: #999; text-align: center; padding: 20px;"
      ))
    else
      total_pages = div(total_threads + @per_page - 1, @per_page)

      # Get threads for current page
      start_index = (page_num - 1) * @per_page
      page_threads = Enum.slice(category_threads, start_index, @per_page)

      # Load threads
      Enum.each(page_threads, fn thread ->
        add_thread_to_ui(thread)
      end)

      # Update pagination controls
      build_pagination(page_num, total_pages)
    end
  end

  # Handle new thread structure
  defp add_thread_to_ui({:thread, id, _category_id, title, author_id, _content, timestamp, reply_count}) do
    # Get author name
    author_name = case :kvs.get(:forum_user, author_id) do
      {:ok, {:forum_user, _, name, _, _, _}} -> name
      _ -> "Unknown"
    end

    thread_link = NITRO.link(
      href: "/app/thread.htm?id=#{id}",
      body: title
    )

    item = NITRO.div(class: :thread_item, body: [
      NITRO.h4(body: thread_link),
      NITRO.span(body: "by #{author_name} • #{reply_count} replies • #{format_time(timestamp)}")
    ])

    :nitro.insert_bottom(:threadsList, item)
  end

  # Handle old thread structure (for backwards compatibility)
  defp add_thread_to_ui({:thread, id, title, author, _content, timestamp}) do
    thread_link = NITRO.link(
      href: "/app/thread.htm?id=#{id}",
      body: title
    )

    item = NITRO.div(class: :thread_item, body: [
      NITRO.h4(body: thread_link),
      NITRO.span(body: "by #{author} • 0 replies • #{format_time(timestamp)}")
    ])

    :nitro.insert_bottom(:threadsList, item)
  end

  defp build_pagination(current_page, total_pages) do
    :nitro.clear(:pagination)

    if total_pages > 1 do
      # Previous button
      if current_page > 1 do
        prev_btn = NITRO.button(
          body: "← Previous",
          postback: {:page, current_page - 1},
          class: :page_btn
        )
        :nitro.insert_bottom(:pagination, prev_btn)
      end

      # Page numbers (show current and nearby pages)
      Enum.each((max(1, current_page - 2))..(min(total_pages, current_page + 2)), fn page ->
        btn_class = if page == current_page, do: "page_btn active", else: "page_btn"
        page_btn = NITRO.button(
          body: "#{page}",
          postback: {:page, page},
          class: btn_class
        )
        :nitro.insert_bottom(:pagination, page_btn)
      end)

      # Next button
      if current_page < total_pages do
        next_btn = NITRO.button(
          body: "Next →",
          postback: {:page, current_page + 1},
          class: :page_btn
        )
        :nitro.insert_bottom(:pagination, next_btn)
      end
    end
  end

  defp format_time(timestamp) when is_integer(timestamp) do
    seconds_ago = :os.system_time(:second) - timestamp
    cond do
      seconds_ago < 60 -> "just now"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> "#{div(seconds_ago, 86400)}d ago"
    end
  end
  defp format_time(_), do: "recently"
end
