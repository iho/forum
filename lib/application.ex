defmodule Forum.Application do
  require N2O
  require Logger
  use Application

  def route(<<"/ws/app/", p::binary>>),  do: route(p)
  def route(<<"index", _::binary>>), do: Forum.Index
  def route(<<"login", _::binary>>), do: Forum.Login
  def route(<<"register", _::binary>>), do: Forum.Register
  def route(<<"categories", _::binary>>), do: Forum.Categories
  def route(<<"category.htm", _::binary>>), do: Forum.Category
  def route(<<"category/", id::binary>>) do
    {Forum.Category, id}
  end
  def route(<<"thread.htm", _::binary>>), do: Forum.Thread
  def route(<<"thread/", id::binary>>) do
    {Forum.Thread, id}
  end
  def route(<<"thread", _::binary>>), do: Forum.Thread

  def finish(state, ctx), do: {:ok, state, ctx}
  def init(state, context) do
      req = N2O.cx(context, :req)
      path = Map.get(req, :path, "")
      qs = Map.get(req, :qs, "")

      Logger.info("Application.init - path: #{inspect(path)}, qs: #{inspect(qs)}")

      # Extract ID from query string if present (for .htm pages)
      {final_module, id_from_query} = case route(path) do
        {module, id} ->
          # ID from path (e.g., /ws/app/thread/123)
          Logger.info("ID from path: #{inspect(id)}")
          {module, id}
        module when module == Forum.Thread ->
          # Check for ?id= in query string
          id = extract_id_from_query(qs)
          Logger.info("Thread ID from query: #{inspect(id)}")
          {module, id}
        module when module == Forum.Category ->
          # Check for ?id= in query string
          id = extract_id_from_query(qs)
          Logger.info("Category ID from query: #{inspect(id)}")
          {module, id}
        module ->
          {module, nil}
      end

      # Store ID in session if present
      if id_from_query && id_from_query != "" do
        Logger.info("Storing ID in session: #{inspect(id_from_query)}")
        :n2o.session(:room, id_from_query)
      end

      {:ok, state, N2O.cx(context, path: path, module: final_module)}
  end

  defp extract_id_from_query(qs) when is_binary(qs) do
    qs
    |> String.split("&")
    |> Enum.find_value("", fn param ->
      case String.split(param, "=", parts: 2) do
        ["id", id] -> URI.decode(id)
        _ -> nil
      end
    end)
  end
  defp extract_id_from_query(_), do: ""

  def start(_, _) do
      :kvs.join()
      :io.format(~c"Application URI: http://localhost:8004/app/categories.htm\n")
      children = [ { Bandit, scheme: :http, port: 8002, plug: Forum.WS },
                   { Bandit, scheme: :http, port: 8004, plug: Forum.Static } ]
      Supervisor.start_link(children, strategy: :one_for_one, name: Forum.Supervisor)
  end
end
