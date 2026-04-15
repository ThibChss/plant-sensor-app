module Notifications
  class WebPushJob < ApplicationJob
    queue_as :default

    DEFAULT_MESSAGE = {
      title: "Green Pulse",
      icon: "/icon.png"
    }.freeze

    private_constant :DEFAULT_MESSAGE

    def perform(message:, endpoint:, p256dh_key:, auth_key:)
      notify(message:, endpoint:, p256dh_key:, auth_key:)
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      PushSubscription.find_by(endpoint:, p256dh_key:, auth_key:)&.destroy
    rescue WebPush::Error => e
      Rails.logger.error "[WebPush] Failed to deliver notification to #{endpoint}: #{e.message}"
    end

    private

    def notify(message:, endpoint:, p256dh_key:, auth_key:)
      WebPush.payload_send(
        message: DEFAULT_MESSAGE.merge({ body: message }).to_json,
        endpoint:,
        p256dh: p256dh_key,
        auth: auth_key,
        vapid: {
          subject: "mailto:support@greenpulse.app",
          public_key: Rails.application.credentials.vapid_key.public,
          private_key: Rails.application.credentials.vapid_key.private
        }
      )
    end
  end
end
