defmodule User do
  require Record
  require KVS

  Record.defrecord(:user,[
    id: :kvs.seq([], []),
    next: [],
    prev: [],
    email: [],
    password: [],
    posts: "/posts/:user_id",
    comments: "/comments/:user_id/:post_id",
    date: {2015, 1, 1},
    last_login: {2015, 1, 1}
  ])

  def login(user, password) do
    if user.password == password do
      user(user, last_login: :erlang.date())
    else
      user
    end
  end

  def save(id, user) do
    :kvs.append(user, Enum.join(["users/", id]))
  end

  def find_by_id(id) do
    res = :kvs.get(:writer, Enum.join(["users/", id]))
    res
    # case res do
    #   {:ok, {:writer, _, _, user , _, _}} ->
    #     # IO.puts("User ID: #{user}")
    #     user
    #   _ ->
    #     IO.puts("No user found")
    # end
  end

  def put(user) do
    :kvs.cut(Enum.join(["users/", user]), user)
  end
end

defmodule Post do
  require Record

  Record.defrecord(:post,
    id: :kvs.seq([], []),
    next: [],
    prev: [],
    title: [],
    body: [],
    comments: "/comms_by_post/:post_id"
  )
end

defmodule Comment do
  require Record

  Record.defrecord(:comment,
    id: :kvs.seq([], []),
    perent: [],
    children: [],
    body: [],
    post: [],
    user: []
  )
end

defmodule Counter do
  require Record
  Record.defrecord(:counter, count: 0)
end
