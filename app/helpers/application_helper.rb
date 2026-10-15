module ApplicationHelper
  # make Markdown display beautifully
  # use if we want to render it in the messages from the AI assistant
    def render_markdown(text)
    Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: "rouge").to_html
  end
end
