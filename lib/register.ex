defmodule Forum.Register do
  require NITRO ; require KVS ; require N2O ; require Logger

  def event(:init) do
    try do
      :nitro.update(:registerBtn, NITRO.button(
        id: :registerBtn,
        body: "Register",
        postback: :register,
        source: [:regName, :regEmail, :regPassword, :regPasswordConfirm]
      ))
    rescue
      e ->
        Logger.error("Register init error: #{inspect(e)}")
        :ok
    end
    []
  end

  def event(:register) do
    name = :nitro.to_binary(:nitro.q(:regName))
    email = :nitro.to_binary(:nitro.q(:regEmail))
    password = :nitro.to_binary(:nitro.q(:regPassword))
    password_confirm = :nitro.to_binary(:nitro.q(:regPasswordConfirm))

    cond do
      name == "" or email == "" or password == "" ->
        show_error("All fields are required")

      password != password_confirm ->
        show_error("Passwords do not match")

      String.length(password) < 6 ->
        show_error("Password must be at least 6 characters")

      not valid_email?(email) ->
        show_error("Invalid email format")

      user_exists?(email) ->
        show_error("Email already registered")

      true ->
        create_user(name, email, password)
    end
  end

  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()

  defp valid_email?(email) do
    String.match?(email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/)
  end

  defp user_exists?(email) do
    case :kvs.get(:forum_user, email) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp hash_password(password) do
    # Simple hash for demo - in production use bcrypt or argon2
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end

  defp create_user(name, email, password) do
    password_hash = hash_password(password)
    timestamp = :os.system_time(:second)

    # Use email as the user ID for simple lookups
    user = {:forum_user, email, name, email, password_hash, timestamp}
    :kvs.put(user)

    # Store user ID in session
    :n2o.session(:user_id, email)
    :n2o.session(:user_name, name)

    # Redirect to categories page
    :nitro.redirect("/app/categories.htm")
  end

  defp show_error(message) do
    :nitro.update(:errorMsg, NITRO.div(
      id: :errorMsg,
      class: :error,
      body: message
    ))
  end
end
