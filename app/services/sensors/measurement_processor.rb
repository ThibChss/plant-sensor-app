module Sensors
  class MeasurementProcessor < ApplicationService
    class MeasurementDataError < StandardError; end

    REQUIRED_DATA = %i[moisture_level_raw uptime_seconds].freeze

    DEFAULT_OPEN_AIR_VALUE = 3835
    DEFAULT_WET_SOIL_VALUE = 1515

    private_constant :DEFAULT_OPEN_AIR_VALUE, :DEFAULT_WET_SOIL_VALUE, :REQUIRED_DATA

    Response = Struct.new(:status, :message)

    def initialize(sensor_id, data)
      @sensor = Sensor.find_by(id: sensor_id)
      @data = data
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
        last_seen_at: Time.current,
        moisture_level_percent:,
        moisture_level_raw:,
        uptime_seconds:
      )
    end

    def moisture_level_percent
      calculate_moisture_level || @sensor.moisture_level_percent
    end

    def uptime_seconds
      @data[:uptime_seconds].to_i
    end

    def moisture_level_raw
      @moisture_level_raw ||= @data[:moisture_level_raw].to_f
    end

    def calculate_moisture_level
      ((DEFAULT_OPEN_AIR_VALUE - moisture_level_raw) / (DEFAULT_OPEN_AIR_VALUE - DEFAULT_WET_SOIL_VALUE) * 100)
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
  end
end
