import { Controller } from "@hotwired/stimulus"

// Copies a readonly input's value to the clipboard on a button click.
// Connects to data-controller="clipboard"
export default class extends Controller {
  static targets = ["source", "button"]

  async copy() {
    this.sourceTarget.select()

    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
    } catch {
      document.execCommand("copy")
    }

    const original = this.buttonTarget.innerHTML
    this.buttonTarget.innerHTML = '<i class="fa-solid fa-check" aria-hidden="true"></i> Copied'
    setTimeout(() => { this.buttonTarget.innerHTML = original }, 1800)
  }
}
