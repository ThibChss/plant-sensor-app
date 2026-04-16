module Notifications
  class WebPushJob < ApplicationJob
    queue_as :default

    DEFAULT_MESSAGE = {
      title: "Green Pulse"
    }

    private_constant :DEFAULT_MESSAGE

    def perform(message:, subscription:)
      @subscription = subscription

      notify(body: message)
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      subscription.destroy
    rescue WebPush::Error => e
      Rails.logger.error "[WebPush] Failed to deliver notification to #{subscription.endpoint}: #{e.message}"
    end

    private

    attr_accessor :subscription

    def notify(body:)
      WebPush.payload_send(
        message: payload(body:),
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {
          subject: "mailto:support@greenpulse.app",
          public_key: Rails.application.credentials.vapid_key.public,
          private_key: Rails.application.credentials.vapid_key.private
        }
      )
    end

    def payload(body:)
      DEFAULT_MESSAGE.merge({ body:, icon: }.compact_blank).to_json
    end

    def icon
      return "/icon.png" if subscription.pwa?
    end
  end
end
