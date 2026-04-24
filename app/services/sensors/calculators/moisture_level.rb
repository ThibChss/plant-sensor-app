module Sensors
  module Calculators
    class MoistureLevel < Base
      DRY_VALUE = 3835
      WET_VALUE = 1340

      WATERING_FREQUENCY_DEFAULTS = {
        'indoor' => {
          'min_days' => 7,
          'max_days' => 10
        },
        'outdoor' => {
          'min_days' => 7,
          'max_days' => 14
        }
      }.freeze

      private_constant :DRY_VALUE, :WET_VALUE, :WATERING_FREQUENCY_DEFAULTS

      def initialize(sensor, raw_value)
        super
        @empty_value = DRY_VALUE
        @full_value = WET_VALUE
        @environment = @sensor.environment || 'indoor'
        @plant = @sensor.plant
      end

      def call
        if @plant.present?
          plant_moisture_level_percent
        else
          calculate_percent.round(1)
        end
      end

      private

      def plant_moisture_level_percent
        @plant_moisture_level_percent ||=
          calculate_decayed_moisture_level_percent.round(1)
      end

      def calculate_target_moisture_level_percent
        @calculate_target_moisture_level_percent ||=
          begin
            minimum = @plant.min_soil_moisture[@environment] || 0
            maximum = @plant.max_soil_moisture[@environment] || 100

            ((calculate_percent - minimum) / (maximum - minimum).to_f * 100).clamp(0, 100)
          end
      end

      def calculate_decayed_moisture_level_percent
        return calculate_target_moisture_level_percent unless @sensor.last_watered_at.present?

        average_days = (minimum_days + maximum_days) / 2.0

        days_since_watered = (Time.current - @sensor.last_watered_at) / 1.day
        decay_factor = (1 - (days_since_watered / average_days)).clamp(0, 1)

        [calculate_target_moisture_level_percent * decay_factor,
         calculate_target_moisture_level_percent].min
      end

      def minimum_days
        @sensor.plant.watering_frequency.dig(@environment, 'min_days') ||
          WATERING_FREQUENCY_DEFAULTS.dig(@environment, 'min_days')
      end

      def maximum_days
        @sensor.plant.watering_frequency.dig(@environment, 'max_days') ||
          WATERING_FREQUENCY_DEFAULTS.dig(@environment, 'max_days')
      end
    end
  end
end
