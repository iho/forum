defmodule Forum.Categories do
  require NITRO ; require KVS ; require N2O ; require Logger

  @per_page 10

  def event(:init) do
    try do
      # Check if user is logged in
      user_name = :n2o.session(:user_name)

      if user_name && user_name != [] && user_name != "" do
        :nitro.update(:userDisplay, NITRO.span(id: :userDisplay, body: "Welcome, #{user_name} "))
        # Hide login/register links and show logout button
        :nitro.wire("document.getElementById('authLinks').style.display = 'none';")
        :nitro.wire("document.getElementById('logoutBtn').style.display = 'inline-block';")

        # Setup logout button
        :nitro.update(:logoutBtn, NITRO.button(
          id: :logoutBtn,
          body: "Logout",
          postback: :logout,
          style: "background: #dc3545; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer;"
        ))

        # Show create thread form
        :nitro.wire("document.getElementById('createThreadSection').style.display = 'block';")

        # Setup create thread button
        :nitro.update(:createThreadBtn, NITRO.button(
          id: :createThreadBtn,
          body: "Create Thread",
          postback: :create_thread,
          source: [:threadTitle, :threadCategory, :threadContent],
          style: "background: #28a745; color: white; border: none; padding: 12px 24px; border-radius: 4px; cursor: pointer; font-size: 16px;"
        ))
      end

      # Load categories
      load_categories()

      # Setup pagination
      setup_pagination(1)
    rescue
      e ->
        Logger.error("Categories init error: #{inspect(e)}")
        :ok
    end
    []
  end

  def event(:logout) do
    # Clear session
    :n2o.session(:user_id, [])
    :n2o.session(:user_name, [])

    # Redirect to login
    :nitro.redirect("/app/login.htm")
  end

  def event(:create_thread) do
    title = :nitro.to_binary(:nitro.q(:threadTitle))
    category_id = :nitro.to_binary(:nitro.q(:threadCategory))
    content = :nitro.to_binary(:nitro.q(:threadContent))
    user_id = :n2o.session(:user_id)

    cond do
      title == "" or content == "" ->
        :nitro.wire("alert('Title and content are required');")

      category_id == "" ->
        :nitro.wire("alert('Please select a category');")

      true ->
        # Create thread
        thread_id = :kvs.seq(:thread, 1) |> :erlang.list_to_binary()
        timestamp = :os.system_time(:second)
        thread = {:thread, thread_id, category_id, title, user_id, content, timestamp, 0}
        :kvs.put(thread)

        # Update category thread count
        case :kvs.get(:category, category_id) do
          {:ok, {:category, id, name, desc, count}} ->
            updated_category = {:category, id, name, desc, count + 1}
            :kvs.put(updated_category)
          _ -> :ok
        end

        # Clear form
        :nitro.wire("document.getElementById('threadTitle').value = '';")
        :nitro.wire("document.getElementById('threadContent').value = '';")
        :nitro.wire("document.getElementById('threadCategory').value = '';")

        # Reload categories to update thread count
        :nitro.clear(:categoriesList)
        # Clear dropdown options (except the first "Select a category")
        :nitro.wire("var sel = document.getElementById('threadCategory'); while(sel.options.length > 1) { sel.remove(1); }")
        load_categories()

        # Reload threads
        setup_pagination(1)

        # Show success message
        :nitro.wire("alert('Thread created successfully!');")
    end
  end

  def event({:page, page_num}) do
    setup_pagination(page_num)
  end

  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()

  defp load_categories() do
    categories = :kvs.all(:category)

    if categories == [] do
      # Create default categories if none exist
      create_default_categories()
    else
      Enum.each(categories, fn category ->
        add_category_to_ui(category)
      end)
    end
  end

  defp create_default_categories() do
    default_cats = [
      {"General Discussion", "Talk about anything"},
      {"Technical Support", "Get help with technical issues"},
      {"Announcements", "Important announcements and updates"}
    ]

    Enum.each(default_cats, fn {name, desc} ->
      id = :kvs.seq(:category, 1) |> :erlang.list_to_binary()
      category = {:category, id, name, desc, 0}
      :kvs.put(category)
      add_category_to_ui(category)
    end)
  end

  defp add_category_to_ui({:category, id, name, description, thread_count}) do
    cat_link = NITRO.link(
      href: "/app/category.htm?id=#{id}",
      body: name
    )

    item = NITRO.div(class: :category_item, body: [
      NITRO.h3(body: cat_link),
      NITRO.p(body: description),
      NITRO.span(class: :thread_count, body: "#{thread_count} threads")
    ])

    :nitro.insert_bottom(:categoriesList, item)

    # Also add to category dropdown
    :nitro.wire("var opt = document.createElement('option'); opt.value = '#{id}'; opt.textContent = '#{name}'; document.getElementById('threadCategory').appendChild(opt);")
  end

  defp setup_pagination(page_num) do
    threads = :kvs.all(:thread) |> Enum.reverse()  # Newest first
    total_threads = length(threads)

    # Clear threads list
    :nitro.clear(:recentThreads)

    if total_threads == 0 do
      # Show "no threads" message
      :nitro.update(:recentThreads, NITRO.p(
        body: "No threads yet. Be the first to create one!",
        style: "color: #999; text-align: center; padding: 20px;"
      ))
    else
      total_pages = div(total_threads + @per_page - 1, @per_page)

      # Get threads for current page
      start_index = (page_num - 1) * @per_page
      page_threads = Enum.slice(threads, start_index, @per_page)

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

    :nitro.insert_bottom(:recentThreads, item)
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

    :nitro.insert_bottom(:recentThreads, item)
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
