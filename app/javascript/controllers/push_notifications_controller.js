import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-notifications"
export default class extends Controller {
  static values = {
    vapidPublicKey: String,
    enabled: Boolean
  }

  CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]').content

  connect() {
    if (this.enabledValue) void this.#subscribeToPushNotifications()
  }

  async #subscribeToPushNotifications() {
    const registration = await navigator.serviceWorker.ready
    let subscription = await registration.pushManager.getSubscription()

    if (!subscription) {
      try {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.vapidPublicKeyValue
        })
      } catch {
        return
      }
    }

    const { endpoint, keys: { p256dh, auth } } = subscription.toJSON()
    const body = JSON.stringify({
      push_subscription: {
        endpoint,
        p256dh_key: p256dh,
        auth_key: auth,
        pwa: this.#checkIfPwa()
      }
    })

    const response = await fetch("/users/push_subscriptions", {
      method: "POST",
      body,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.CSRF_TOKEN
      }
    })

    if (!response.ok) {
      console.error(`[PushNotifications] Unexpected response: ${response.status}`)
    }
  }

  #checkIfPwa() {
   return window.matchMedia('(display-mode: standalone)').matches
    || window.navigator.standalone === true;
  }
}
