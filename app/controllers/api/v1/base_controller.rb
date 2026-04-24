# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Basic::ControllerMethods

      private

      def sensor
        @sensor ||= authenticate_with_http_basic do |uid, secret_key|
          Sensor.find_by(uid:, secret_key:)
        end
      end
    end
  end
end
