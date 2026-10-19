module ApplicationHelper
  # make Markdown display beautifully
  # use if we want to render it in the messages from the AI assistant
    def render_markdown(text)
    Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: "rouge").to_html
  end

  # round avatar for an agent: their uploaded photo, or a user-tie icon if they have none
  def agent_avatar(user, size: 48)
    if user.avatar.attached?
      image_tag user.avatar, alt: user.user_name, class: "rounded-circle object-fit-cover flex-shrink-0", width: size, height: size
    else
      tag.div class: "rounded-circle bg-primary bg-opacity-10 text-primary d-flex align-items-center justify-content-center flex-shrink-0",
              style: "width: #{size}px; height: #{size}px;" do
        tag.i class: "fa-solid fa-user-tie"
      end
    end
  end
end
