import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "plantSearchInput",
    "results",
    "selectedPlantBlock",
    "selectedPlantSummary"
  ]

  static outlets = [
    "sensor-setup-wizard"
  ]

  static values = {
    prepareUrl: String
  }

  debounceMs = 300

  CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
  PREPARE_URL = "/plants/prepare"

  ERROR_MESSAGE = "Impossible d’enregistrer la plante. Réessayez."

  connect() {
    this.lastPlantSnapshot  = null
    this.searchTimer        = null
  }

  disconnect() {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer)
      this.searchTimer = null
    }
  }

  getSearchQuery() {
    return this.hasPlantSearchInputTarget ? this.plantSearchInputTarget.value : ""
  }

  setSearchQuery(value) {
    if (this.hasPlantSearchInputTarget) this.plantSearchInputTarget.value = value ?? ""
  }

  getLastPlantSnapshot() {
    return this.lastPlantSnapshot
  }

  setLastPlantSnapshot(snapshot) {
    this.lastPlantSnapshot = snapshot
  }

  searchPlants(event) {
    const query = event.target.value.trim()

    if (this.searchTimer) {
      clearTimeout(this.searchTimer)
      this.searchTimer = null
    }

    if (query.length < 3) {
      this.#setResultsPlaceholder()

      return
    }

    this.searchTimer = window.setTimeout(() => {
      this.searchTimer = null

      void this.#loadPlantResults(query)
    }, this.debounceMs)
  }

  async restoreSearchStep() {
    if (!this.hasPlantSearchInputTarget) return

    const query = this.plantSearchInputTarget.value.trim()

    if (query.length >= 3) {
      await this.#loadPlantResults(query)
    } else {
      this.#setResultsPlaceholder()
    }
  }

  async selectPlant(event) {
    const plantRow = event.target.closest("[data-plant-json]")
    if (!plantRow?.dataset.plantJson) return

    try {
      this.plant = JSON.parse(decodeURIComponent(plantRow.dataset.plantJson))
    } catch {
      return
    }

    this.sensorSetupWizardOutlet.showGrowthLoader()

    try {
      const data = await this.#fetchPlantResults(this.plant)

      if (!data.ok) {
        this.#showPlantPrepareError(data.message || this.ERROR_MESSAGE)
        await this.restoreSearchStep()

        return
      }

      this.#clearPlantHiddenInputs()

      const hidden    = document.createElement("input")
      hidden.type     = "hidden"
      hidden.name     = "sensor[plant_id]"
      hidden.value    = data.plant_id

      this.#formElement.appendChild(hidden)

      this.lastPlantSnapshot = {
        name: this.plant.name,
        scientific_name: this.plant.scientific_name,
        image_url: this.plant.image_url
      }

      this.renderPlantSummary(this.plant)
      this.#setResultsPlaceholder()

      this.element.dispatchEvent(
        new CustomEvent("sensor-setup:plant-prepared", {
          bubbles: true,
          detail: { min_soil_moisture: data.min_soil_moisture }
        })
      )
    } catch {
      this.#showPlantPrepareError(this.ERROR_MESSAGE)

      await this.restoreSearchStep()
    } finally {
      this.sensorSetupWizardOutlet.hideGrowthLoader()
    }
  }

  renderPlantSummary(plant) {
    if (!this.hasSelectedPlantSummaryTarget) return

    const imgUrl      = this.#escapeHtml(plant.image_url)
    const name        = this.#escapeHtml(plant.name)
    const scientific  = this.#escapeHtml(plant.scientific_name)

    this.selectedPlantSummaryTarget.innerHTML = `
      <div class="flex items-center gap-5 p-6">
        <img src="${imgUrl}" alt="" class="h-24 w-24 shrink-0 rounded-2xl object-cover shadow-inner ring-2 ring-white/80">
        <div class="min-w-0 flex-1 text-left">
          <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-pulse-moss">Plante associée</p>
          <p class="mt-1 font-alegreya text-xl font-black text-pulse-forest">${name}</p>
          <p class="mt-1 text-sm italic text-pulse-moss">${scientific}</p>
        </div>
      </div>
    `

    if (this.hasSelectedPlantBlockTarget) {
      this.selectedPlantBlockTarget.classList.remove("hidden")
    }
  }

  injectPlantId(plantId) {
    this.#clearPlantHiddenInputs()

    const hidden    = document.createElement("input")

    hidden.type     = "hidden"
    hidden.name     = "sensor[plant_id]"
    hidden.value    = plantId

    this.#formElement.appendChild(hidden)
  }

  clearPlantSelection() {
    this.#clearPlantHiddenInputs()
    this.lastPlantSnapshot = null

    if (this.hasSelectedPlantBlockTarget) {
      this.selectedPlantBlockTarget.classList.add("hidden")
    }

    if (this.hasSelectedPlantSummaryTarget) {
      this.selectedPlantSummaryTarget.innerHTML = ""
    }
  }

  /** Reset search UI when leaving the setup flow (e.g. Turbo page cache). */
  resetSearchUi() {
    this.setSearchQuery("")
    this.#setResultsPlaceholder()
    this.clearPlantSelection()
  }

  // PRIVATE METHODS

  async #fetchPlantResults(plant) {
    return await fetch(this.PREPARE_URL, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.CSRF_TOKEN || ""
        },
        body: JSON.stringify({
          plant: {
            trefle_id: String(plant.trefle_id),
            name: plant.name,
            scientific_name: plant.scientific_name,
            image_url: plant.image_url,
            translated_name: plant.translated_name
          }
        })
      })
      .then((response) => response.json())
  }

  #plantResultButtonHtml(plant) {
    const payload           = encodeURIComponent(JSON.stringify(plant))
    const name              = this.#escapeHtml(plant.name)
    const scientific        = this.#escapeHtml(plant.scientific_name)
    const imgUrl            = this.#escapeHtml(plant.image_url)

    return `
      <button type="button"
              class="w-full text-left p-4 bg-white/50 rounded-2xl mb-2 flex items-center gap-4 cursor-pointer hover:bg-white"
              data-plant-json="${payload}">
        <img src="${imgUrl}" alt="" class="w-12 h-12 rounded-xl object-cover pointer-events-none">
        <div class="pointer-events-none">
          <p class="font-bold text-pulse-forest">${name}</p>
          <p class="text-[10px] text-pulse-moss">${scientific}</p>
        </div>
      </button>
    `
  }

  async #loadPlantResults(query) {
    const response  = await fetch(`/plants/search?query=${encodeURIComponent(query)}`)
    const plants    = await response.json()

    if (plants.length === 0) {
      this.resultsTarget.innerHTML = `
        <p class="text-[10px] text-center text-pulse-moss/60 italic py-8">Aucune plante trouvée.</p>
      `

      return
    }

    this.resultsTarget.innerHTML = plants.map((plant) => this.#plantResultButtonHtml(plant)).join("")
  }

  #escapeHtml(str) {
    if (str == null) return ""

    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
  }

  #showPlantPrepareError(message) {
    alert(message)
  }

  #setResultsPlaceholder() {
    this.resultsTarget.innerHTML = `
      <p class="text-[10px] text-center text-pulse-moss/40 italic py-8">Tapez le nom d'une plante pour commencer...</p>
    `
  }

  #clearPlantHiddenInputs() {
    this.#formElement
      .querySelectorAll(
        'input[type="hidden"][name^="sensor[plant]"], input[type="hidden"][name="sensor[plant_id]"]'
      )
      .forEach((element) => element.remove())
  }

  get #formElement() {
    return this.element.querySelector("form")
  }
}
