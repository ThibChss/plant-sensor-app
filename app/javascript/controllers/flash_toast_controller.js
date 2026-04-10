import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static values = {
    dismissAfter: {
      type: Number,
      default: 3000
    }
  }

  connect() {
    this.timeoutId = window.setTimeout(() => this.dismiss(), this.dismissAfterValue)
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        this.element.classList.remove('-translate-y-12', 'opacity-0')
        this.element.classList.add('translate-y-0', 'opacity-100')
      })
    })
  }

  disconnect() {
    window.clearTimeout(this.timeoutId)
  }

  close() {
    this.dismiss()
  }

  dismiss() {
    window.clearTimeout(this.timeoutId)
    this.element.classList.remove('translate-y-0', 'opacity-100')
    this.element.classList.add('-translate-y-12', 'opacity-0')
    window.setTimeout(() => {
      this.element.remove()
    }, 520)
  }
}
