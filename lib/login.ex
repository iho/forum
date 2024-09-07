defmodule Sample.Login do
  require NITRO
  require Logger

  def event(:init) do
    login_button =
      NITRO.button(
        id: :login_button,
        class: "btn btn-primary",
        body: "Login",
        postback: :login,
        source: [:email, :password]
      )

    :nitro.update(:login_button, login_button)
  end

  def event(:login) do
    email = :nitro.to_list(:nitro.q(:email))
    password = :nitro.to_binary(:nitro.q(:password))
    IO.inspect({email, password})
    :n2o.user(email)
    :n2o.session(:email, email)
    :nitro.wire("ws.close();")
    :nitro.redirect(["/app/index.html"])
  end

  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()
end
