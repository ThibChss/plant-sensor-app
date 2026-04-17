module Sensors
  class UidValidator < ApplicationService
    UID_FORMAT = /\AGP-[A-Z0-9]{5}-[A-Z0-9]{5}\z/i

    Response = Struct.new(:ok, :message, :sensor)

    private_constant :UID_FORMAT

    def initialize(uid)
      @uid = uid
    end

    def call
      return response[:blank] if @uid.blank?
      return response[:invalid] unless valid_uid?
      return response[:unavailable] unless sensor.present?

      response[:valid]
    end

    private

    def valid_uid?
      UID_FORMAT.match?(@uid)
    end

    def sensor
      @sensor ||=
        Sensor.find_by(uid: @uid, user_id: Current.user.id, plant_id: nil) ||
        Sensor.find_by(uid: @uid, user_id: nil)
    end

    def response
      {
        valid: Response.new(
          true,
          nil,
          sensor
        ),
        invalid: Response.new(
          false,
          I18n.t('sensors.setup.uid_validation.invalid_format')
        ),
        unavailable: Response.new(
          false,
          I18n.t('sensors.setup.uid_validation.unavailable')
        ),
        blank: Response.new(
          false,
          I18n.t('sensors.setup.uid_validation.blank')
        )
      }
    end
  end
end
