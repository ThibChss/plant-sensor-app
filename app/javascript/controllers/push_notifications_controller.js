import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="push-notifications"
export default class extends Controller {
  static values = {
    vapidPublicKey: String
  }

  CSRF_TOKEN = document.querySelector('meta[name="csrf-token"]').content

  connect() {
    void this.#subscribeToPushNotifications()
  }

  async #subscribeToPushNotifications() {
    const registration = await navigator.serviceWorker.ready
    let subscription = await registration.pushManager.getSubscription()

    if (!subscription) {
      subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: this.vapidPublicKeyValue
      })

      if (!subscription) {
        console.error("Failed to subscribe to push notifications")
      }
    }

    const { endpoint, keys: { p256dh, auth } } = subscription.toJSON()
    const body = JSON.stringify({
      push_subscription: {
        endpoint,
        p256dh_key: p256dh,
        auth_key: auth
      }
    })

    await fetch("/users/push_subscriptions", {
      method: "POST",
      body,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.CSRF_TOKEN
      }
    })
  }
}
