module Sensors
  module Calculators
    class BatteryLevel < Base
      BATTERY_LEVEL_FULL = 4095
      BATTERY_LEVEL_EMPTY = 0

      private_constant :BATTERY_LEVEL_FULL, :BATTERY_LEVEL_EMPTY

      def initialize(sensor, raw_value)
        super
        @empty_value = BATTERY_LEVEL_EMPTY
        @full_value = BATTERY_LEVEL_FULL
      end

      def call
        calculate_percent.round(1)
      end
    end
  end
end
