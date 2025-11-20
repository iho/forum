defmodule Forum.Login do
  require NITRO ; require KVS ; require N2O ; require Logger

  def event(:init) do
    try do
      :nitro.update(:loginBtn, NITRO.button(
        id: :loginBtn,
        body: "Login",
        postback: :login,
        source: [:loginEmail, :loginPassword]
      ))
    rescue
      e ->
        Logger.error("Login init error: #{inspect(e)}")
        :ok
    end
    []
  end

  def event(:login) do
    email = :nitro.to_binary(:nitro.q(:loginEmail))
    password = :nitro.to_binary(:nitro.q(:loginPassword))

    cond do
      email == "" or password == "" ->
        show_error("Email and password are required")

      true ->
        authenticate_user(email, password)
    end
  end

  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()

  defp authenticate_user(email, password) do
    case :kvs.get(:forum_user, email) do
      {:ok, {:forum_user, _id, name, ^email, password_hash, _created_at}} ->
        if verify_password(password, password_hash) do
          # Store user info in session
          :n2o.session(:user_id, email)
          :n2o.session(:user_name, name)

          # Redirect to categories
          :nitro.redirect("/app/categories.htm")
        else
          show_error("Invalid email or password")
        end

      _ ->
        show_error("Invalid email or password")
    end
  end

  defp hash_password(password) do
    :crypto.hash(:sha256, password) |> Base.encode16(case: :lower)
  end

  defp verify_password(password, password_hash) do
    hash_password(password) == password_hash
  end

  defp show_error(message) do
    :nitro.update(:errorMsg, NITRO.div(
      id: :errorMsg,
      class: :error,
      body: message
    ))
  end
end
