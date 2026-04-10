import { Controller } from "@hotwired/stimulus"
import { formatUidString } from "sensor_setup/uid_format"

export default class extends Controller {
  static targets = [
    "uidInput",
    "uidFeedback",
    "uidNextButton"
  ]

  static values = {
    blank: String,
    invalid: String,
    unavailable: String,
    serverError: String
  }

  UID_REGEXP = /^GP-[A-Z0-9]{5}-[A-Z0-9]{5}$/i

  VALIDATION_URL = "/sensors/setup/validate_uid"

  getUid() {
    return this.hasUidInputTarget ? this.uidInputTarget.value.trim() : ""
  }

  setUid(value) {
    if (!this.hasUidInputTarget || !value) return

    this.uidInputTarget.value = formatUidString(String(value))
  }

  formatUid(event) {
    const input     = event.target
    const formatted = formatUidString(input.value);

    if (input.value === formatted) return

    input.value     = formatted
    const end       = formatted.length

    input.setSelectionRange(end, end)
  }

  clearUidFeedback() {
    if (!this.hasUidFeedbackTarget) return

    this.uidFeedbackTarget.textContent = ""
    this.uidFeedbackTarget.classList.add("hidden")
  }

  resetFormUid() {
    this.clearUidFeedback()
    this.#disableNextButton(false)
  }

  async validateUid() {
    this.clearUidFeedback()

    const uid                 = formatUidString(this.uidInputTarget.value)
    this.uidInputTarget.value = uid

    if (uid.length === 0) return this.#displayErrorMessage(this.#blankMessage())
    if (!this.UID_REGEXP.test(uid)) return this.#displayErrorMessage(this.#invalidMessage())

    const url                 = this.VALIDATION_URL;
    const checkUrl            = `${url}?${new URLSearchParams({ uid })}`;

    this.#disableNextButton()

    return await this.#fetchValidationResponse(checkUrl)
  }

  // PRIVATE METHODS

  #blankMessage() {
    if (this.hasBlankValue && this.blankValue !== "") return this.blankValue

    return "Entrez l'identifiant du capteur."
  }

  #invalidMessage() {
    if (this.hasInvalidValue && this.invalidValue !== "") return this.invalidValue

    return "Le format doit être GP-XXXXX-XXXXX (5 caractères entre chaque tiret)."
  }

  #unavailableMessage() {
    if (this.hasUnavailableValue && this.unavailableValue !== "") return this.unavailableValue

    return "Aucun capteur disponible avec cet identifiant."
  }

  #serverErrorMessage() {
    if (this.hasServerErrorValue && this.serverErrorValue !== "") return this.serverErrorValue

    return "Impossible de vérifier le capteur. Réessayez."
  }

  async #fetchValidationResponse(url) {
    try {
      const response = await fetch(url, {
        headers: {
          Accept: "application/json"
        }
      })
      .then(response => response.json())

      if (response.ok) return true

      return this.#displayErrorMessage(response.message || this.#unavailableMessage())
    } catch {
      return this.#displayErrorMessage(this.#serverErrorMessage())
    } finally {
      this.#disableNextButton(false)
    }
  }

  #disableNextButton(disabled = true) {
    if (this.hasUidNextButtonTarget) {
      this.uidNextButtonTarget.disabled = disabled
    }
  }

  #displayErrorMessage(message) {
    this.#showUidError(message)

    return false
  }

  #showUidError(message) {
    if (this.hasUidFeedbackTarget) {
      this.uidFeedbackTarget.textContent = message
      this.uidFeedbackTarget.classList.remove("hidden")
    } else {
      alert(message)
    }
  }
}
