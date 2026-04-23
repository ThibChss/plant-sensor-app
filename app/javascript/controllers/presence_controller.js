import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="presence"
export default class extends Controller {
  PRESENCE_URL = "/users/presence"
  CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]').content

  connect() {
    this.handleVisibility = this.#handleVisibility.bind(this)
    document.addEventListener("visibilitychange", this.handleVisibility)

    this.#startPing()
  }

  disconnect() {
    this.#stopPing()
    document.removeEventListener("visibilitychange", this.handleVisibility)
  }

  // PRIVATE

  #handleVisibility() {
    document.hidden ? this.#stopPing() : this.#startPing()
  }

  #startPing() {
    this.#ping()
    this.interval = setInterval(() => this.#ping(), 60000)
  }

  #stopPing() {
    clearInterval(this.interval)
  }

  async #ping() {
    if (document.hidden) return

    await fetch(this.PRESENCE_URL, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.CSRF_TOKEN }
    })
  }
}
