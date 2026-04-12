import { Controller } from "@hotwired/stimulus"
import { formatUidString } from "sensor_setup/uid_format"

export default class extends Controller {
  static targets = [
    "step",
    "indicator",
    "form",
    "growthLoader"
  ]

  static outlets = [
    "sensor-setup-uid",
    "sensor-setup-plant-search",
    "sensor-setup-threshold"
  ]

  static values = {
    prefilledUid: {
      type: String,
      default: ""
    },
    prefilledSecret: {
      type: String,
      default: ""
    }
  }

  WIZARD_STORAGE_KEY = "plantSensorSetupWizard"
  WIZARD_STORAGE_VERSION = 2

  UUID_CHECK_REGEXP = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
  UID_CHECK_REGEXP = /^[A-Z0-9]{2}-[A-Z0-9]{5}-[A-Z0-9]{5}$/i

  VALID_STEPS = [0, 1, 2]

  #beforeCacheListener = null

  connect() {
    this.#beforeCacheListener = this.#onBeforeTurboCache.bind(this)
    document.addEventListener("turbo:before-cache", this.#beforeCacheListener)

    if (this.#shouldPrefillFromQr()) {
      this.#clearWizardStorage()
      queueMicrotask(() => this.#prefillFromQr())

      return
    }

    if (this.#isReloadNavigation()) {
      const savedStep = this.#readWizardState()

      if (savedStep && this.#validateWizardState(savedStep)) {
        this.currentStep = savedStep.step

        queueMicrotask(() => {
          this.#applyRestoredWizardFields(savedStep)
          this.#showStep()
        })

        return
      }

      this.#clearWizardStorage()
    } else {
      this.#clearWizardStorage()
    }

    this.currentStep = 0

    queueMicrotask(() => this.#showStep())
  }

  disconnect() {
    if (this.#beforeCacheListener) {
      document.removeEventListener("turbo:before-cache", this.#beforeCacheListener)
      this.#beforeCacheListener = null
    }
  }

  async next() {
    if (this.currentStep === 0) {
      const validationSuccess = await this.sensorSetupUidOutlet.validateUid()

      if (!validationSuccess) return
    }

    this.#updateCurrentStep()
  }

  previous() {
    if (this.currentStep === 2) {
      this.sensorSetupPlantSearchOutlet.clearPlantSelection()
      this.sensorSetupThresholdOutlet.clearRecommendedMinSoil()
    }

    this.#updateCurrentStep(false)
  }

  onPlantPrepared(event) {
    const { min_soil_moisture: minSoilMoisture } = event.detail
    this.sensorSetupThresholdOutlet.setRecommendedMinSoil(minSoilMoisture ?? null)

    this.#updateCurrentStep()
  }

  clearWizardOnSubmit() {
    this.#clearWizardStorage()
  }

  showGrowthLoader() {
    if (!this.hasGrowthLoaderTarget) return

    this.growthLoaderTarget.classList.remove("hidden")
    this.growthLoaderTarget.setAttribute("aria-busy", "true")
  }

  hideGrowthLoader() {
    if (!this.hasGrowthLoaderTarget) return

    this.growthLoaderTarget.classList.add("hidden")
    this.growthLoaderTarget.removeAttribute("aria-busy")
  }

  // PRIVATE METHODS

  #updateCurrentStep(increment = true) {
    increment ? this.currentStep++ : this.currentStep--

    this.#showStep()
  }

  #showStep() {
    this.#applyStepVisibilityAndSideEffects()
    this.#persistWizardState()
  }

  #applyStepVisibilityAndSideEffects() {
    this.stepTargets.forEach((element, stepIndex) => {
      element.classList.toggle("hidden", stepIndex !== this.currentStep)
    })

    this.indicatorTargets.forEach((element, indicatorIndex) => {
      element.classList.toggle("bg-pulse-forest", indicatorIndex <= this.currentStep)
      element.classList.toggle("bg-pulse-sage/20", indicatorIndex > this.currentStep)
    })

    if (this.currentStep === 1) {
      void this.sensorSetupPlantSearchOutlet.restoreSearchStep()
    }

    if (this.currentStep === 2) {
      this.sensorSetupThresholdOutlet.applyMoistureFromEnvironment()
    }
  }

  #isReloadNavigation() {
    const navEntry = window.performance.getEntriesByType("navigation")[0]

    return navEntry?.type === "reload"
  }

  #readWizardState() {
    try {
      const stepData = sessionStorage.getItem(this.WIZARD_STORAGE_KEY)
      if (!stepData) return null

      return JSON.parse(stepData)
    } catch {
      return null
    }
  }

  #validateWizardState(saved) {
    if (!saved || saved.version !== this.WIZARD_STORAGE_VERSION) return false

    const { step, uid, plantId, plantSnapshot } = saved

    if (!this.VALID_STEPS.includes(step)) return false

    if (step >= 1) {
      if (!this.UID_CHECK_REGEXP.test(formatUidString(uid))) return false
    }

    if (step >= 2) {
      if (!this.#isValidPlantId(plantId)) return false
      if (!this.#isValidPlantSnapshot(plantSnapshot)) return false
    }

    return true
  }

  #isValidPlantSnapshot(snapshot) {
    return (
      snapshot &&
      typeof snapshot.name === "string" &&
      typeof snapshot.scientific_name === "string" &&
      typeof snapshot.image_url === "string"
    )
  }

  #isValidPlantId(value) {
    return typeof value === "string" && value && this.UUID_CHECK_REGEXP.test(value)
  }

  #applyRestoredWizardFields(saved) {
    const { uid, secretKey, plantSearchQuery, plantSnapshot, minSoilMoisture, plantId, step } = saved

    if (uid) this.sensorSetupUidOutlet.setUid(uid)
    if (secretKey) this.sensorSetupUidOutlet.setSecretKey(secretKey)
    if (plantSearchQuery) this.sensorSetupPlantSearchOutlet.setSearchQuery(plantSearchQuery)

    this.sensorSetupPlantSearchOutlet.setLastPlantSnapshot(plantSnapshot ?? null)
    this.sensorSetupThresholdOutlet.setRecommendedMinSoil(minSoilMoisture ?? null)

    if (step >= 2 && plantId) {
      this.sensorSetupPlantSearchOutlet.injectPlantId(plantId)

      if (plantSnapshot) this.sensorSetupPlantSearchOutlet.renderPlantSummary(plantSnapshot)
    }
  }

  #persistWizardState() {
    try {
      const uid               = this.sensorSetupUidOutlet.getUid()
      const secretKey         = this.sensorSetupUidOutlet.getSecretKey()
      const plantId           = this.formTarget.querySelector('input[name="sensor[plant_id]"]')?.value
      const searchQuery       = this.sensorSetupPlantSearchOutlet.getSearchQuery()
      const plantSnapshot     = this.sensorSetupPlantSearchOutlet.getLastPlantSnapshot()
      const minSoilMoisture   = this.sensorSetupThresholdOutlet.getRecommendedMinSoil()

      const payload           = {
        version: this.WIZARD_STORAGE_VERSION,
        step: this.currentStep,
        uid,
        secretKey: secretKey || null,
        plantId: plantId || null,
        plantSnapshot,
        minSoilMoisture,
        plantSearchQuery: searchQuery
      }

      sessionStorage.setItem(this.WIZARD_STORAGE_KEY, JSON.stringify(payload))
    } catch {}
  }

  #clearWizardStorage() {
    try {
      sessionStorage.removeItem(this.WIZARD_STORAGE_KEY)
    } catch {}
  }

  #onBeforeTurboCache() {
    if (!this.element.isConnected) return

    this.#resetWizardForLeavingPage()
  }

  #resetWizardForLeavingPage() {
    this.#clearWizardStorage()
    this.currentStep = 0

    if (this.hasFormTarget) {
      this.formTarget.reset()
    }

    this.sensorSetupUidOutlet.resetFormUid()
    this.sensorSetupPlantSearchOutlet.resetSearchUi()
    this.sensorSetupThresholdOutlet.clearRecommendedMinSoil()

    this.#applyStepVisibilityAndSideEffects()
    this.hideGrowthLoader()

    this.#clearWizardStorage()
  }

  #shouldPrefillFromQr() {
    const uid    = (this.prefilledUidValue || "").trim()
    const secret = (this.prefilledSecretValue || "").trim()

    return uid.length > 0 && secret.length > 0
  }

  #prefillFromQr() {
    this.sensorSetupUidOutlet.setUid(this.prefilledUidValue)
    this.sensorSetupUidOutlet.setSecretKey(this.prefilledSecretValue)
    this.sensorSetupUidOutlet.clearUidFeedback()
    this.#stripQrParamsFromUrl()
    this.currentStep = 0
    this.#showStep()
  }

  #stripQrParamsFromUrl() {
    const url = new URL(window.location.href)

    if (!url.searchParams.has("uid") && !url.searchParams.has("secret_key")) return

    url.searchParams.delete("uid")
    url.searchParams.delete("secret_key")

    const next = `${url.pathname}${url.search}${url.hash}`

    window.history.replaceState({}, "", next)
  }
}
