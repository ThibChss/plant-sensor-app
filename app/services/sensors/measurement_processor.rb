module Sensors
  class MeasurementProcessor < ApplicationService
    class MeasurementDataError < StandardError; end

    REQUIRED_DATA = %i[
      moisture_level_raw
      uptime_seconds
    ].freeze

    DRY_VALUE = 3835
    WET_VALUE = 1340

    SPIKE_THRESHOLD = 20

    private_constant :DRY_VALUE, :WET_VALUE, :REQUIRED_DATA, :SPIKE_THRESHOLD

    Response = Struct.new(:status, :message)

    def initialize(sensor_id, data)
      @sensor = Sensor.find_by(id: sensor_id)
      @data = data
      @last_reading = @sensor&.readings&.last
      @timestamp = Time.current
    end

    def call
      validate_data?

      if @sensor
        update_sensor_current_data

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
        last_watered_at:
      )
    end

    def moisture_level_percent
      @moisture_level_percent ||=
        calculate_moisture_level || @sensor.moisture_level_percent
    end

    def uptime_seconds
      @data[:uptime_seconds].to_i
    end

    def moisture_level_raw
      @moisture_level_raw ||= @data[:moisture_level_raw].to_f
    end

    def calculate_moisture_level
      ((DRY_VALUE - moisture_level_raw) / (DRY_VALUE - WET_VALUE).to_f * 100)
        .clamp(0, 100)
        .round(1)
    end

    def response
      {
        success: Response.new(:ok, { message: 'Data saved successfully' }),
        unauthorized: Response.new(:unauthorized, { error: 'Access denied: Invalid UID or Secret Key' }),
        unprocessable_content: lambda { |error|
          Response.new(:unprocessable_content, { error: "Internal error: #{error.message}" })
        }
      }
    end

    def validate_data?
      return if REQUIRED_DATA.all? { @data.key?(it) }

      raise MeasurementDataError, 'Missing required data: moisture_level_raw and uptime_seconds'
    end

    def last_watered_at
      watered? ? @timestamp : @sensor.last_watered_at
    end

    def watered?
      return false unless @last_reading

      (moisture_level_percent - @last_reading.moisture_level_percent) >= SPIKE_THRESHOLD
    end
  end
end
