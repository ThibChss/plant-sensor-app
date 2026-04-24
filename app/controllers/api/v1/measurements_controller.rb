# frozen_string_literal: true

module Api
  module V1
    class MeasurementsController < BaseController
      rate_limit to: 60, within: 1.minute, name: 'api-v1-measurements',
                 with: -> { render json: { error: 'Rate limit exceeded' }, status: :too_many_requests }

      def update
        render json: processor.message, status: processor.status
      end

      private

      def measurement_params
        params.require(:data).permit(:moisture_level_raw, :uptime_seconds, :battery_level_raw)
      end

      def processor
        @processor ||= Sensors::MeasurementProcessor.call(sensor&.id, measurement_params)
      end
    end
  end
end
