import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="setting-toggle"
export default class extends Controller {
  static targets = [
    'knob'
  ]

  static values  = {
    url: String,
    enabled: Boolean
  }

  CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]').content

  enabledValueChanged() {
    this.element.classList.toggle('bg-pulse-forest', this.enabledValue)
    this.element.classList.toggle('bg-pulse-sage/30', !this.enabledValue)
    this.knobTarget.classList.toggle('translate-x-6', this.enabledValue)
    this.knobTarget.classList.toggle('translate-x-1', !this.enabledValue)
  }

  async toggle() {
    const response = await fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': this.CSRF_TOKEN
      }
    })

    if (response.ok) {
      const { enabled } = await response.json()

      this.enabledValue = enabled
    }
  }
}
