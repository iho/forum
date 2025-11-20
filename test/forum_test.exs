defmodule ForumTest do
  use ExUnit.Case
  doctest Forum

  setup do
    :kvs.join()
    :kvs.initialize(Forum.KVS)
    :ok
  end

  test "create and retrieve thread" do
    id = :kvs.next_id("thread", 1)
    thread = {:thread, id, "Test Thread", "User1", "Content", 123456}
    :kvs.add(thread)
    assert {:ok, ^thread} = :kvs.get(:thread, id)
  end

  test "create and retrieve post" do
    id = :kvs.next_id("post", 1)
    post = {:post, id, 1, "User2", "Reply", 123457}
    :kvs.add(post)
    assert {:ok, ^post} = :kvs.get(:post, id)
  end
end
