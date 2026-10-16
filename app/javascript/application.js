// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "@popperjs/core"
import * as bootstrap from "bootstrap"

// Global initialization of Bootstrap tooltips across Turbo visits
document.addEventListener("turbo:load", () => {
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  tooltipTriggerList.forEach((el) => {
    bootstrap.Tooltip.getOrCreateInstance(el)
  })
})

document.addEventListener("turbo:before-cache", () => {
  const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]')
  tooltipTriggerList.forEach((el) => {
    const instance = bootstrap.Tooltip.getInstance(el)
    if (instance) instance.dispose()
  })
})
