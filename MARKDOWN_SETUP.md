# Markdown Support Setup

## Install Dependencies

Run the following command to install the new markdown dependencies:

```bash
cd /Users/ihor/forum
mix deps.get
```

Then restart your nodemon process.

## Features

### Safe Markdown Rendering
- **Parser**: `earmark` converts markdown to HTML
- **Sanitizer**: `html_sanitize_ex` prevents XSS attacks
- All user content is sanitized before rendering

### Supported Markdown

Users can now format their posts and replies with:

- **Bold**: `**text**` or `__text__`
- *Italic*: `*text*` or `_text_`
- `Inline code`: `` `code` ``
- Code blocks: ` ```language ... ``` `
- [Links](url): `[text](url)`
- Lists: `- item` or `1. item`
- Quotes: `> quote`
- Headings: `# H1`, `## H2`, etc.

### Where It Works

Markdown is now supported in:
1. Thread content (when creating new threads)
2. Thread replies
3. All display automatically renders markdown with proper styling

### Security

- All HTML output is sanitized using `HtmlSanitizeEx.markdown_html/1`
- Only safe HTML tags and attributes are allowed
- XSS attacks are prevented
- Script tags and event handlers are stripped

## Implementation

### Files Modified

1. **`mix.exs`** - Added dependencies
2. **`lib/markdown.ex`** - New markdown rendering module
3. **`lib/thread.ex`** - Updated to render markdown in threads and replies
4. **`priv/static/thread.htm`** - Added markdown CSS and user notice
5. **`priv/static/categories.htm`** - Added markdown notice to create thread form

### Usage Example

```elixir
# In your code
html = Forum.Markdown.to_html("**Hello** *world*!")
# Returns: "<p><strong>Hello</strong> <em>world</em>!</p>"
```

The module handles nil/non-string inputs gracefully and always returns safe HTML.
