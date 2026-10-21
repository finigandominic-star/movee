import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Reloads the page after a short wait, e.g. while a client PDF is still being read in the background.
// Connects to data-controller="auto-reload"
export default class extends Controller {
  static values = { delay: { type: Number, default: 2000 } }

  connect() {
    this.timeout = setTimeout(() => {
      Turbo.visit(window.location.href, { action: "replace" })
    }, this.delayValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}
