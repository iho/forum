-ifndef(FORUM_HRL).
-define(FORUM_HRL, true).

-record(forum_user, {id, name, email, password_hash, created_at}).
-record(category, {id, name, description, thread_count}).
-record(thread, {id, category_id, title, author_id, content, timestamp, reply_count}).
-record(post, {id, thread_id, author_id, content, timestamp}).

-endif.
