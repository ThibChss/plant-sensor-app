import { Controller } from "@hotwired/stimulus"
import { formatUidString } from "sensor_setup/uid_format"
import { loadI18n } from "sensor_setup/i18n"

export default class extends Controller {
  static targets = [
    "uidInput",
    "secretInput",
    "uidFeedback",
    "uidNextButton"
  ]

  UID_REGEXP = /^GP-[A-Z0-9]{5}-[A-Z0-9]{5}$/i
  VALIDATE_UID_URL = "/sensors/setup/validate_uid"

  connect() {
    void loadI18n()
  }

  getUid() {
    return this.hasUidInputTarget ? this.uidInputTarget.value.trim() : ""
  }

  setUid(value) {
    if (!this.hasUidInputTarget || !value) return

    this.uidInputTarget.value = formatUidString(String(value))
  }

  setSecretKey(value) {
    if (!this.hasSecretInputTarget) return

    this.secretInputTarget.value = value ?? ""
  }

  getSecretKey() {
    return this.hasSecretInputTarget ? this.secretInputTarget.value.trim() : ""
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
    if (this.hasSecretInputTarget) this.secretInputTarget.value = ""
  }

  async validateUid() {
    this.i18n = await loadI18n()

    this.clearUidFeedback()

    const uid                 = formatUidString(this.uidInputTarget.value)
    this.uidInputTarget.value = uid

    if (uid.length === 0) return this.#displayErrorMessage(this.#blankMessage())
    if (!this.UID_REGEXP.test(uid)) return this.#displayErrorMessage(this.#invalidMessage())

    const checkUrl = `${this.VALIDATE_UID_URL}?${new URLSearchParams({ uid })}`

    this.#disableNextButton()

    return await this.#fetchValidationResponse(checkUrl)
  }

  // PRIVATE METHODS

  #blankMessage() {
    return this.i18n.t("sensors.setup.uid_validation.blank")
  }

  #invalidMessage() {
    return this.i18n.t("sensors.setup.uid_validation.invalid_format")
  }

  #unavailableMessage() {
    return this.i18n.t("sensors.setup.uid_validation.unavailable")
  }

  #serverErrorMessage() {
    return this.i18n.t("sensors.setup.uid_validation.server_error")
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
