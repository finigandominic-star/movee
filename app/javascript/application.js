// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import * as bootstrap from "bootstrap"

// Fields that failed validation get a tooltip spelling out why: "<label> <error message>"
const initValidationTooltips = () => {
  document.querySelectorAll(".is-invalid").forEach((field) => {
    const feedback = field.parentElement.querySelector(".invalid-feedback") ||
                     field.parentElement.parentElement?.querySelector(".invalid-feedback")
    if (!feedback || field.dataset.bsToggle) return

    // Simple Form already writes full sentences ("User name is required…"); other forms give just the message
    const message = feedback.textContent.trim()
    const label = field.id && document.querySelector(`label[for="${field.id}"]`)
    const name = label && /^[a-z]/.test(message) ? label.textContent.replace(/\*|\(optional\)/g, "").trim() : ""
    field.dataset.bsToggle = "tooltip"
    field.dataset.bsTitle = [name, message].filter(Boolean).join(" ")
    field.dataset.bsTrigger = "hover focus"
    field.dataset.bsPlacement = "top"
  })
}

// Global initialization of Bootstrap tooltips across Turbo visits
// (turbo:render covers forms re-rendered with errors after a failed submit)
const initTooltips = () => {
  initValidationTooltips()
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  tooltipTriggerList.forEach((el) => {
    bootstrap.Tooltip.getOrCreateInstance(el)
  })
}
document.addEventListener("turbo:load", initTooltips)
document.addEventListener("turbo:render", initTooltips)

document.addEventListener("turbo:before-cache", () => {
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  tooltipTriggerList.forEach((el) => {
    const instance = bootstrap.Tooltip.getInstance(el)
    if (instance) instance.dispose()
  })
})
