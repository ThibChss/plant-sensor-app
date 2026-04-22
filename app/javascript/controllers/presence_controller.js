import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="presence"
export default class extends Controller {
  PRESENCE_URL = "/users/presence"
  CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]').content

  connect() {
    this.ping()
    this.interval = setInterval(() => this.ping(), 60000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  async ping() {
    await fetch(this.PRESENCE_URL, {
      method: "PATCH",
      headers: { "X-CSRF-Token": this.CSRF_TOKEN }
    })
  }
}
