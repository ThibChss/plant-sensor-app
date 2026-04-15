import { Controller } from "@hotwired/stimulus"
import { loadI18n } from "sensor_setup/i18n"

// Connects to data-controller="time-ago"
export default class TimeAgoController extends Controller {
  static values = {
    time: String
  }

  static #UNITS = [
    { threshold: 60,       divisor: 1,        key: null        },
    { threshold: 3600,     divisor: 60,       key: "minute"    },
    { threshold: 86400,    divisor: 3600,     key: "hour"      },
    { threshold: 604800,   divisor: 86400,    key: "day"       },
    { threshold: 2629746,  divisor: 604800,   key: "week"      },
    { threshold: 31556926, divisor: 2629746,  key: "month"     },
    { threshold: Infinity, divisor: 31556926, key: "year"      },
  ]

  connect() {
    void loadI18n()
    void this.update()

    this.interval = setInterval(() => void this.update(), 60000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  async update() {
    const date                = new Date(this.timeValue)
    if (Number.isNaN(date.getTime())) return

    this.element.textContent  = await this.#timeAgo(date)
  }

  async #timeAgo(date) {
    this.i18n                 = await loadI18n()
    const seconds             = Math.floor((new Date() - date) / 1000)
    const { divisor, key }    = TimeAgoController.#UNITS.find(unit => seconds < unit.threshold)

    if (!key) return this.i18n.t("sensors.time_ago.less_than_minute")

    return this.#timeAgoByUnit(seconds, divisor, key)
  }

  #timeAgoByUnit(seconds, divisor, keyBase) {
    const count   = Math.floor(seconds / divisor)
    const key     = count === 1 ? keyBase : `${keyBase}s`

    return this.i18n.t(`sensors.time_ago.${key}`, { count })
  }
}
