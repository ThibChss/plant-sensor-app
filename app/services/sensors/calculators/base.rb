module Sensors
  module Calculators
    class Base < ApplicationService
      alias_call :compute

      def initialize(sensor, raw_value)
        @sensor = sensor
        @raw_value = raw_value
      end

      private

      def calculate_percent
        @calculate_percent ||=
          ((@raw_value - @empty_value) / (@full_value - @empty_value).to_f * 100)
          .clamp(0, 100)
      end
    end
  end
end
