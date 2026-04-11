module Api
  module V1
    class MeasurementsController < ActionController::API
      def update
        render json: processor.message, status: processor.status
      end

      private

      def sensor
        @sensor ||= Sensor.find_by(uid: params.require(:sensor_uid), secret_key: params.require(:secret_key))
      end

      def measurement_params
        params.require(:data).permit(:moisture_level_raw, :uptime_seconds)
      end

      def processor
        @processor ||= Sensors::MeasurementProcessor.call(sensor&.id, measurement_params)
      end
    end
  end
end
