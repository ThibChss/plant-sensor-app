module Sensors
  class UidValidator < ApplicationService
    UID_FORMAT = /\AGP-[A-Z0-9]{5}-[A-Z0-9]{5}\z/i

    private_constant :UID_FORMAT

    def initialize(uid)
      @uid = uid
    end

    def call
      return response[:blank] if @uid.blank?
      return response[:invalid] unless valid_uid?
      return response[:unavailable] unless sensor_exists?

      response[:valid]
    end

    private

    def valid_uid?
      UID_FORMAT.match?(@uid)
    end

    def sensor_exists?
      Sensor.exists?(uid: @uid, user_id: nil)
    end

    def response
      {
        valid: {
          ok: true
        },
        invalid: {
          ok: false,
          message: 'Le format doit être GP-XXXXX-XXXXX (5 caractères entre chaque tiret).'
        },
        unavailable: {
          ok: false,
          message: 'Aucun capteur disponible avec cet identifiant. Vérifiez l’UID ou qu’il n’est pas déjà lié à un compte.'
        },
        blank: {
          ok: false,
          message: 'Entrez l’identifiant du capteur.'
        }
      }
    end
  end
end
