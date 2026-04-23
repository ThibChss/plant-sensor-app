module Api
  module V1
    class ConnectionController < ActionController::API
      def update
        return head :unauthorized unless sensor
        return head :ok unless paired? && sensor.user.present?

        sensor.user.notify(
          message: I18n.t('api.v1.connection.paired'),
          notifiable: sensor,
          notification_type: :sensor_connected,
          flash_type: :notice,
          data: {
            first_connection: first_time_pairing?
          }
        )

        head :ok
      end

      private

      def sensor
        @sensor ||= Sensor.find_by(uid: connection_params[:sensor_uid], secret_key: connection_params[:secret_key])
      end

      def paired?
        ActiveModel::Type::Boolean.new.cast(connection_params[:paired])
      end

      def first_time_pairing?
        Notifications::SensorConnected
          .where(user_id: sensor.user_id, notifiable: sensor)
          .where("data @> ?", { first_connection: true }.to_json)
          .none?
      end

      def connection_params
        params.require(:connection).permit(:sensor_uid, :secret_key, :paired)
      end
    end
  end
end
