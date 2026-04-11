module Broadcaster
  module Sensor
    extend ActiveSupport::Concern

    included do
      after_update_commit :broadcast_sensor_card, if: -> { user_id.present? }
    end

    private

    def broadcast_sensor_card
      I18n.with_locale(broadcast_locale) do
        broadcast_replace_to(
          stream_name,
          target: dom_id,
          partial: 'sensors/sensor_card',
          locals: { sensor: self }
        )
      end
    end

    def broadcast_locale
      user&.locale&.to_sym || I18n.default_locale
    end

    def stream_name
      [user, :sensors]
    end
  end
end
