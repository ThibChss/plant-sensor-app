module Broadcaster
  module Sensor
    extend ActiveSupport::Concern

    included do
      after_update_commit :broadcast_sensor
    end

    private

    def broadcast_sensor
      return unless user_id.present?

      broadcast_sensor_card
      broadcast_sensor_show
    end

    def broadcast_sensor_card
      using_locale do
        broadcast_replace_later_to(
          index_stream_name,
          target: dom_id,
          partial: 'sensors/sensor_card',
          locals: {
            sensor: self
          }
        )
      end
    end

    def broadcast_sensor_show
      using_locale do
        broadcast_replace_later_to(
          show_stream_name,
          target: "show_stats_#{dom_id}",
          partial: 'sensors/show_live_stats',
          locals: {
            sensor: self
          }
        )
      end
    end

    def index_stream_name
      [user, :sensors]
    end

    def show_stream_name
      [user, dom_id]
    end

    def using_locale(&)
      I18n.with_locale(broadcast_locale, &)
    end

    def broadcast_locale
      user&.locale&.to_sym || I18n.default_locale
    end
  end
end
