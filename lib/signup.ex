defmodule Sample.Signup do
  require NITRO ; require Logger
  def event(:init) do
      login_button = NITRO.button(id: :signup_button, body: "Signup ready", postback: :signup, source: [:email, :username, :password])
      :nitro.update(:signup_button, login_button)
  end
  def event(:signup) do
      username = :nitro.to_list(:nitro.q(:username))
      email = :nitro.to_binary(:nitro.q(:email))
      password = :nitro.to_binary(:nitro.q(:password))
      hash = Argon2.hash_pwd_salt(password)
      IO.inspect({username, email, hash})
      client = Resend.client(api_key: System.get_env("RESEND_API_KEY"))

      Resend.Emails.send(client, %{
        from: "onboarding@forum.dev",
        to: email,
        subject: "Hello World",
        html: "<p>Congrats on sending your <strong>first email</strong>!</p>"
      })
      :n2o.user(username)
      :n2o.session(:email, email)
      :nitro.wire("ws.close();")
      :nitro.redirect(["/app/login.html?"])
  end
  def event(unexpected), do: unexpected |> inspect() |> Logger.warning()
end
