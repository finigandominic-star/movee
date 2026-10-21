import { Controller } from "@hotwired/stimulus"

// Keeps a "expires in ..." label live, ticking down client-side instead of
// freezing at whatever it said when the page was first rendered.
// Connects to data-controller="countdown"
export default class extends Controller {
  static targets = ["text"]
  static values = { expiresAt: String }

  connect() {
    this.render()
    this.timer = setInterval(() => this.render(), 30000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  render() {
    const remainingMs = new Date(this.expiresAtValue).getTime() - Date.now()
    this.textTarget.textContent = remainingMs <= 0 ? "has expired" : `expires in ${this.humanize(remainingMs)}`
  }

  humanize(ms) {
    const minutes = Math.round(ms / 60000)
    if (minutes < 1) return "less than a minute"
    if (minutes < 45) return `${minutes} minute${minutes === 1 ? "" : "s"}`

    const hours = Math.round(ms / 3600000)
    if (hours < 24) return hours === 1 ? "about 1 hour" : `about ${hours} hours`

    const days = Math.round(ms / 86400000)
    return days === 1 ? "1 day" : `${days} days`
  }
}
