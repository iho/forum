defmodule Forum.KVS do
  require Record
  Record.defrecord(:kvs_schema, :schema, name: :kvs, tables: [])
  Record.defrecord(:kvs_table, :table,
    name: :table,
    container: false,
    type: :set,
    fields: [],
    keys: [],
    copy_type: :disc_copies,
    instance: {},
    mappings: []
  )

  # Extract records from our forum.hrl file
  Enum.each(Record.extract_all(from_lib: "forum/include/forum.hrl"), fn {name, definition} ->
    Record.defrecord(name, definition)
  end)

  def metainfo() do
    kvs_schema(name: :forum, tables: [
      kvs_table(name: :forum_user, fields: [:id, :name, :email, :password_hash, :created_at]),
      kvs_table(name: :category, fields: [:id, :name, :description, :thread_count]),
      kvs_table(name: :thread, fields: [:id, :category_id, :title, :author_id, :content, :timestamp, :reply_count]),
      kvs_table(name: :post, fields: [:id, :thread_id, :author_id, :content, :timestamp])
    ])
  end
end
