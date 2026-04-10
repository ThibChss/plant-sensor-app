import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "thresholdLabel",
    "thresholdInput",
    "environmentSelect",
    "locationSelect",
    "thresholdRecommendedLabel"
  ]

  static values = {
    envLocations: Object,
    locationLabels: Object
  }

  DEFAULT_MOISTURE_THRESHOLD = 25

  connect() {
    this.clearRecommendedMinSoil()
    this.syncLocationOptions()
    this.applyMoistureFromEnvironment()
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

  environmentChanged() {
    this.syncLocationOptions()
    this.applyMoistureFromEnvironment()
  }

  updateThreshold(e) {
    this.thresholdLabelTarget.textContent = `${e.target.value}%`

    this.#syncRecommendedLabel()
  }

  applyMoistureFromEnvironment() {
    if (!this.hasThresholdInputTarget) return

    const environment                 = this.#currentEnvironmentValue()
    const recommended                 = this.#recommendedMoistureForEnvironment(environment)
    const value                       = recommended ?? this.DEFAULT_MOISTURE_THRESHOLD

    this.thresholdInputTarget.value       = String(value)
    this.thresholdLabelTarget.textContent = `${value}%`

    this.#syncRecommendedLabel()
  }

  syncLocationOptions() {
    if (!this.hasLocationSelectTarget) return

    const environment = this.#currentEnvironmentValue()
    const keys        = this.envLocationsValue[environment] || []
    const labels      = this.locationLabelsValue || {}
    const select      = this.locationSelectTarget
    const previous    = select.value

    select.replaceChildren()

    keys.forEach((key) => {
      const opt = document.createElement("option")
      opt.value = key
      opt.textContent = labels[key] || key
      select.appendChild(opt)
    })

    if (keys.includes(previous)) select.value = previous
  }

  // PRIVATE METHODS

  #currentEnvironmentValue() {
    if (this.hasEnvironmentSelectTarget) return this.#readSelectValue(this.environmentSelectTarget)

    return this.#readSelectValue(this.element.querySelector('[name="sensor[environment]"]'))
  }

  #readSelectValue(element) {
    return element?.value || "indoor"
  }

  #recommendedMoistureForEnvironment(environment) {
    if (this.#isInvalidRecommendedMoisture()) return null

    const moistureValue           = this.recommendedMinSoilMoisture[environment]
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

    const environment     = this.#currentEnvironmentValue()
    const recommended     = this.#recommendedMoistureForEnvironment(environment)
    const current         = Number(this.thresholdInputTarget.value)

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
