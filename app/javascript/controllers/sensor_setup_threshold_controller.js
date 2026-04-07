import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "thresholdLabel",
    "thresholdInput",
    "locationSelect",
    "thresholdRecommendedLabel"
  ]

  DEFAULT_MOISTURE_THRESHOLD = 25

  connect() {
    this.clearRecommendedMinSoil()
  }

  getRecommendedMinSoil() {
    return this.recommendedMinSoilMoisture
  }

  setRecommendedMinSoil(value) {
    this.recommendedMinSoilMoisture = value
  }

  clearRecommendedMinSoil() {
    this.recommendedMinSoilMoisture = null
  }

  locationChanged() {
    this.applyMoistureFromLocation()
  }

  updateThreshold(e) {
    this.thresholdLabelTarget.textContent = `${e.target.value}%`

    this.#syncRecommendedLabel()
  }

  applyMoistureFromLocation() {
    if (!this.hasThresholdInputTarget) return

    const location                        = this.#currentLocationValue()
    const recommended                     = this.#recommendedMoistureForLocation(location)
    const value                           = recommended ?? this.DEFAULT_MOISTURE_THRESHOLD

    this.thresholdInputTarget.value       = String(value)
    this.thresholdLabelTarget.textContent = `${value}%`

    this.#syncRecommendedLabel()
  }

  // PRIVATE METHODS

  #currentLocationValue() {
    if (this.hasLocationSelectTarget) return this.#locationInputValue(this.locationSelectTarget)

    return this.#locationInputValue(this.element.querySelector('[name="sensor[location]"]'))
  }

  #locationInputValue(element) {
    return element?.value || "indoor"
  }

  #recommendedMoistureForLocation(location) {
    if (this.#isInvalidRecommendedMoisture()) return null

    const moistureValue           = this.recommendedMinSoilMoisture[location]
    const formattedMoistureValue  = Number(moistureValue)

    if (this.#isInvalidMoistureValue(formattedMoistureValue)) return null

    return Math.min(100, Math.max(0, Math.round(formattedMoistureValue)))
  }

  #isInvalidMoistureValue(value) {
    return value == null || value === "" || Number.isNaN(Number(value))
  }

  #isInvalidRecommendedMoisture() {
    return (this.recommendedMinSoilMoisture == null || typeof this.recommendedMinSoilMoisture !== "object")
  }

  #syncRecommendedLabel() {
    if (!this.hasThresholdRecommendedLabelTarget || !this.hasThresholdInputTarget) return

    const location          = this.#currentLocationValue()
    const recommended       = this.#recommendedMoistureForLocation(location)
    const current           = Number(this.thresholdInputTarget.value)

    this.thresholdRecommendedLabelTarget.classList.toggle(
      "hidden", !this.#shouldShowRecommendedLabel(recommended, current)
    )
  }

  #shouldShowRecommendedLabel(recommended, current) {
    return (
      recommended != null &&
      !Number.isNaN(current) &&
      current === recommended
    )
  }
}
