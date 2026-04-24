module Sensors
  class MeasurementProcessor < ApplicationService
    class MeasurementDataError < StandardError; end

    REQUIRED_DATA = %i[
      moisture_level_raw
      uptime_seconds
      battery_level_raw
    ].freeze

    SPIKE_THRESHOLD = 20

    private_constant :REQUIRED_DATA, :SPIKE_THRESHOLD

    Response = Struct.new(:status, :message)

    def initialize(sensor_id, data)
      @sensor = Sensor.find_by(id: sensor_id)
      @data = data
      @last_reading = @sensor&.readings&.last
      @timestamp = Time.current
    end

    def call
      validate_data!

      if @sensor
        update_sensor_current_data
        notify_moisture_low

        response[:success]
      else
        response[:unauthorized]
      end
    rescue ActiveRecord::RecordInvalid, MeasurementDataError => e
      response[:unprocessable_content].call(e)
    end

    private

    def update_sensor_current_data
      @sensor.update!(
        last_seen_at: @timestamp,
        moisture_level_percent:,
        moisture_level_raw:,
        uptime_seconds:,
        battery_level_raw:,
        battery_level_percent:,
        last_watered_at:
      )
    end

    def moisture_level_percent
      @moisture_level_percent ||=
        Sensors::Calculators::MoistureLevel.compute(@sensor, moisture_level_raw)
    end

    def uptime_seconds
      @data[:uptime_seconds].to_i
    end

    def moisture_level_raw
      @moisture_level_raw ||= @data[:moisture_level_raw].to_f
    end

    def battery_level_raw
      @data[:battery_level_raw].to_i
    end

    def battery_level_percent
      Sensors::Calculators::BatteryLevel.compute(@sensor, battery_level_raw)
    end

    def response
      {
        success: Response.new(:ok, { message: 'Data saved successfully' }),
        unauthorized: Response.new(:unauthorized, { error: 'Access denied: Invalid UID or Secret Key' }),
        unprocessable_content: lambda { |error|
          Rails.logger.error("[MeasurementProcessor] #{error.class}: #{error.message}")

          Response.new(:unprocessable_content, {
                         error: "[MeasurementProcessor] Unable to process measurement data: #{error.message}"
                       })
        }
      }
    end

    def validate_data!
      return if REQUIRED_DATA.all? { @data.key?(it) }

      raise MeasurementDataError, "Missing required data: #{REQUIRED_DATA.join(', ')}"
    end

    def last_watered_at
      watered? ? @timestamp : @sensor.last_watered_at
    end

    def watered?
      return false unless @last_reading

      (moisture_level_percent - @last_reading.moisture_level_percent) >= SPIKE_THRESHOLD
    end

    def notify_moisture_low
      return unless @sensor.thirsty? && not_notified?

      @sensor.user.notify(
        notifiable: @sensor,
        notification_type: :moisture_low,
        flash_type: :warning,
        data: {
          last_watered_at: @sensor.last_watered_at
        }
      )
    end

    def not_notified?
      Notifications::MoistureLow
        .where(user_id: @sensor.user_id, notifiable: @sensor)
        .where("data @> ?", { last_watered_at: @sensor.last_watered_at }.to_json)
        .none?
    end
  end
end
