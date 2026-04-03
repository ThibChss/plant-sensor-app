import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "visibilityButton", "showIcon", "hideIcon"]

  toggle(event) {
    event.preventDefault()

    const input = this.inputTarget
    const wasMasked = input.type === "password"

    input.type = wasMasked ? "text" : "password"

    const passwordVisible = input.type === "text"

    this.visibilityButtonTarget.setAttribute("aria-pressed", String(passwordVisible))
    this.visibilityButtonTarget.setAttribute(
      "aria-label",
      passwordVisible ? "Masquer le mot de passe" : "Afficher le mot de passe"
    )

    // Eye = show password (when field is masked). Eye-off = hide password (when plain text).
    this.showIconTarget.classList.toggle("hidden", passwordVisible)
    this.hideIconTarget.classList.toggle("hidden", !passwordVisible)
  }
}
