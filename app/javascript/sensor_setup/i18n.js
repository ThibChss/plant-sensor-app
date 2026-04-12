import { I18n } from "i18n-js"

let loadPromise = null

/**
 * Loads `/locales.json` once, builds a shared I18n instance (same pattern as `uid_format.js`).
 * Safe to call from multiple controllers; subsequent calls reuse the same promise / instance.
 */
export function loadI18n() {
  if (!loadPromise) {
    loadPromise = (async () => {
      const response = await fetch("/locales.json", { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`Failed to load locales: ${response.status}`)

      const i18n = new I18n(await response.json())
      i18n.locale = document.documentElement.lang || "en"

      return i18n
    })()
  }

  return loadPromise
}
