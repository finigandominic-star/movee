import { Controller } from "@hotwired/stimulus"

// Live, client-side search for an index page that's already rendered in full.
// Filters the visible cards/rows on every keystroke and offers a dropdown of
// matching suggestions to jump straight to; a reset button clears back to
// the unfiltered list. The "q" param + server-side search still apply on
// a normal page load (e.g. the first visit, or a submit with JS disabled) —
// this only adds instant feedback on top of what's already on the page.
// Connects to data-controller="search-autocomplete"
export default class extends Controller {
  static targets = ["input", "item", "suggestions", "clear"]

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    const matches = new Set()

    this.itemTargets.forEach(item => {
      const visible = !query || item.dataset.name.toLowerCase().includes(query)
      item.hidden = !visible
      if (visible && query) matches.add(item.dataset.name)
    })

    if (this.hasClearTarget) this.clearTarget.hidden = !query
    this.renderSuggestions(query ? [...matches].slice(0, 8) : [])
  }

  renderSuggestions(matches) {
    if (!this.hasSuggestionsTarget) return

    this.suggestionsTarget.hidden = matches.length === 0
    this.suggestionsTarget.innerHTML = matches
      .map(name => `<button type="button" class="dropdown-item">${this.escapeHtml(name)}</button>`)
      .join("")
  }

  pick(event) {
    if (event.target.tagName !== "BUTTON") return

    this.inputTarget.value = event.target.textContent
    this.filter()
    this.suggestionsTarget.hidden = true
    this.inputTarget.focus()
  }

  // Also used as the reset button's click handler: clears the box, shows
  // everything again, and (via preventDefault) skips the link's normal
  // navigation to the plain index URL — that navigation is the no-JS fallback.
  reset(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.filter()
    this.inputTarget.focus()
  }

  closeSuggestions(event) {
    if (this.hasSuggestionsTarget && !this.element.contains(event.target)) {
      this.suggestionsTarget.hidden = true
    }
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
