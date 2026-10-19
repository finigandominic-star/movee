module ApplicationHelper
  # make Markdown display beautifully
  # use if we want to render it in the messages from the AI assistant
  def render_markdown(text)
    Kramdown::Document.new(text, input: 'GFM', syntax_highlighter: "rouge").to_html
  end

  # Human name for a chain. An agent-given nickname wins; otherwise it is told from the viewer's
  # side: their own listing in the chain is the address they recognise, e.g. "12 Elm Rd +3".
  def chain_name(chain)
    return chain.name if chain.name.present?

    txs = chain.transactions.sort_by(&:id)
    return "Chain ##{chain.id}" if txs.empty?

    viewer = current_user if respond_to?(:current_user)
    own = viewer && txs.find { |tx| tx.user_id == viewer.id || tx.property&.user_id == viewer.id }
    anchor = (own || txs.first).property&.short_address || "Chain ##{chain.id}"
    others = txs.size - 1
    others.positive? ? "#{anchor} +#{others}" : anchor
  end

  # Secondary line for a chain, e.g. "4 properties · Chain #12"
  def chain_summary(chain)
    "#{pluralize(chain.transactions.size, 'property', plural: 'properties')} · Chain ##{chain.id}"
  end

  # Buyer / Seller pills for a client
  def client_role_tags(party)
    tags = []
    tags << tag.span("Seller", class: "badge bg-primary") if party.seller?
    tags << tag.span("Buyer", class: "badge bg-info") if party.buyer?
    tags << tag.span("Contact", class: "badge bg-light") if tags.empty?
    safe_join(tags, " ")
  end

  # Icon-only button/link label: visible icon plus an accessible name
  def icon_label(icon, label)
    safe_join([tag.i(class: "fa-solid #{icon}", aria: { hidden: true }), tag.span(label, class: "visually-hidden")])
  end

  # round avatar for an agent: their uploaded photo, or a user-tie icon if they have none
  def agent_avatar(user, size: 48)
    if user.avatar.attached?
      image_tag user.avatar, alt: user.user_name, class: "rounded-circle object-fit-cover flex-shrink-0", width: size, height: size
    else
      tag.span class: "rounded-circle bg-primary bg-opacity-10 text-primary d-flex align-items-center justify-content-center flex-shrink-0",
               style: "width: #{size}px; height: #{size}px;" do
        tag.i class: "fa-solid fa-user-tie"
      end
    end
  end

  # agent's avatar next to their name, for anywhere an agent is listed
  def agent_with_avatar(user, size: 24, name_class: nil)
    tag.span class: "d-inline-flex align-items-center gap-2" do
      safe_join([agent_avatar(user, size: size), tag.span(user.user_name.presence || user.email, class: name_class)])
    end
  end
end
