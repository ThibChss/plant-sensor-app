# frozen_string_literal: true

module Api
  module V1
    class ConnectionController < BaseController
      rate_limit to: 30, within: 1.minute, name: 'api-v1-connection',
                 with: -> { render json: { error: 'Rate limit exceeded' }, status: :too_many_requests }

      def update
        return head :unauthorized unless sensor
        return head :ok unless paired? && sensor.user.present?

        sensor.user.notify(
          notifiable: sensor,
          notification_type:,
          flash_type: :notice,
          data: {
            first_connection: first_time_pairing?
          }
        )

        head :ok
      end

      private

      def paired?
        ActiveModel::Type::Boolean.new.cast(params.dig(:connection, :paired))
      end

      def notification_type
        first_time_pairing? ? :sensor_connected : :sensor_back
      end

      def first_time_pairing?
        @first_time_pairing ||=
          Notifications::SensorConnected
          .where(user_id: sensor.user_id, notifiable: sensor)
          .where("data @> ?", { first_connection: true }.to_json)
          .none?
      end
    end
  end
end
