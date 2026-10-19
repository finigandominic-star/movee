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
end
