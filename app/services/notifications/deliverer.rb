module Notifications
  class Deliverer < ApplicationService
    class DeliveryError < StandardError; end

    NotificationContext = Struct.new(:user, :message, :notification_type, :flash_type, :notifiable, :data)

    alias_call :notify!

    def initialize(user:, message:, notification_type:, flash_type:, notifiable:, data:)
      @user = user
      @context = NotificationContext.new(message:, notification_type:, flash_type:, notifiable:, data:)
    end

    def call
      validate_notification_type!

      user.active? ? notify_in_app : notify_web_push
    end

    private

    attr_reader :user, :context

    def notify_in_app
      Turbo::StreamsChannel.broadcast_append_to(user, target: :flash, html: flash_html)

      create_notification!(data: { via: :flash, flash_type: context.flash_type })
    end

    def notify_web_push
      return notify_in_app unless user.push_notifications_enabled?

      user.push_subscriptions.each { it.deliver(message: context.message) }

      create_notification!(data: { via: :web_push })
    end

    def flash_html
      ApplicationController.render(
        Components::Toast.new(type: context.flash_type, message: context.message),
        layout: false
      ).html_safe
    end

    def create_notification!(data:)
      notification_class.create!(
        user:,
        notifiable: context.notifiable,
        data: context.data.merge(**data, message: context.message)
      )
    end

    def notification_class
      @notification_class ||=
        "Notifications::#{context.notification_type.to_s.classify}".constantize
    end

    def validate_notification_type!
      notification_class
    rescue NameError
      raise DeliveryError, "Invalid notification type: #{context.notification_type}"
    end
  end
end
