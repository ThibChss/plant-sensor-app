import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Connects to data-controller="setting-toggle"
export default class extends Controller {
  static targets = ['knob']
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
    this.enabledValue = !this.enabledValue

    const response = await fetch(this.urlValue, {
      method: 'PATCH',
      headers: {
        'Accept': 'text/vnd.turbo-stream.html',
        'X-CSRF-Token': this.CSRF_TOKEN
      }
    })

    if (response.ok) {
      Turbo.renderStreamMessage(await response.text())
    } else {
      this.enabledValue = !this.enabledValue
    }
  }
}
