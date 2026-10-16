import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Connects to data-controller="tooltip"
export default class extends Controller {
  connect() {
    this.initTooltips()
  }

  initTooltips() {
    if (this.element.getAttribute("data-bs-toggle") === "tooltip") {
      bootstrap.Tooltip.getOrCreateInstance(this.element)
    }

    this.element.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
      bootstrap.Tooltip.getOrCreateInstance(el)
    })
  }

  disconnect() {
    const directInstance = bootstrap.Tooltip.getInstance(this.element)
    if (directInstance) directInstance.dispose()

    this.element.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(el => {
      const instance = bootstrap.Tooltip.getInstance(el)
      if (instance) instance.dispose()
    })
  }
}
