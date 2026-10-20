import { Controller } from "@hotwired/stimulus"

// Search-or-browse picker for a list of client choices.
// Typing filters by name; focusing the box or pressing the toggle opens the full list like a dropdown.
// When closed with no search, only the selected client (if any) is shown, so the list stays compact.
// Connects to data-controller="client-search"
export default class extends Controller {
  static targets = ["input", "item", "empty", "details", "toggle"]

  connect() {
    this.open = false
    this.filter()
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    let matches = 0

    this.itemTargets.forEach(item => {
      const visible = query ? item.dataset.name.toLowerCase().includes(query) : (this.open || this.isChecked(item))
      item.hidden = !visible
      if (visible) matches++
    })

    if (this.hasEmptyTarget) this.emptyTarget.hidden = !query || matches > 0
    if (this.hasToggleTarget) this.toggleTarget.setAttribute("aria-expanded", this.open)
    this.toggleDetails()
  }

  show() {
    this.open = true
    this.filter()
  }

  toggle() {
    this.open = !this.open
    this.filter()
    if (this.open) this.inputTarget.focus()
  }

  // Picking a client collapses the list down to them
  choose(event) {
    if (event.target.type !== "radio") return

    this.open = false
    this.inputTarget.value = ""
    this.filter()
  }

  closeOnOutsideClick(event) {
    if (!this.open || this.element.contains(event.target)) return

    this.open = false
    this.filter()
  }

  // Extra fields only matter once a client is picked
  toggleDetails() {
    if (!this.hasDetailsTarget) return

    this.detailsTarget.hidden = !this.itemTargets.some(item => this.isChecked(item))
  }

  isChecked(item) {
    return item.querySelector("input[type=radio]")?.checked
  }
}
