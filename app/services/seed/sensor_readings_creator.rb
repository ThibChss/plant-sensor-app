module Seed
  class SensorReadingsCreator < ApplicationService
    HOURS_PER_DAY = 24
    DAYS = 180

    DRY_VALUE = 3835
    WET_VALUE = 1340

    private_constant :DRY_VALUE, :WET_VALUE, :HOURS_PER_DAY, :DAYS

    def initialize(sensor:)
      @sensor = sensor

      @min = sensor.moisture_threshold
      @max = sensor.plant&.max_soil_moisture&.dig(sensor.environment) || 70

      @readings = []
    end

    def call
      puts "Creating readings for #{@sensor.nickname}..."

      generate_readings

      puts "✅ #{@readings.count} readings created"
    end

    private

    def generate_readings
      current_moisture = rand(@min..@max).to_f
      timestamp = DAYS.days.ago

      DAYS.times do |day|
        HOURS_PER_DAY.times do |hour|
          # Gradual moisture drop (evaporation + plant consumption)
          current_moisture -= rand(0.3..0.8)

          # Watering event: once every 7-14 days, moisture jumps back up
          if current_moisture < @min || ((day % rand(7..14)).zero? && hour == rand(8..20))
            current_moisture = rand((@max - 10)..@max).to_f
          end

          current_moisture = current_moisture.clamp(0, 100)

          @readings << {
            id: SecureRandom.uuid,
            sensor_id: @sensor.id,
            moisture_level_percent: current_moisture.round(1),
            moisture_level_raw: percent_to_raw(current_moisture),
            uptime_seconds: (day * 86400) + (hour * 3600),
            created_at: timestamp,
            updated_at: timestamp
          }

          timestamp += 1.hour
        end
      end

      @sensor.readings.insert_all!(@readings)
    end

    def percent_to_raw(percent)
      (DRY_VALUE - (percent / 100.0 * (DRY_VALUE - WET_VALUE))).round
    end
  end
end
