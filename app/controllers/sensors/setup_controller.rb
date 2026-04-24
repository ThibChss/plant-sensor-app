module Sensors
  class SetupController < ApplicationController
    rate_limit to: 60, within: 1.minute, only: :validate_uid, name: 'setup-validate-uid',
               by: -> { Current.user.id }

    def new
      if params[:token].present?
        handle_token_param

        return if performed?
      end

      @sensor = session_sensor || Sensor.new
    end

    def validate_uid
      validation.sensor.update_column(:user_id, Current.user.id) if validation.ok

      render json: validation.to_h.except(:sensor)
    end

    def create
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless plant && sensor.update(sensor_params)

        session.delete(:setup_sensor_id)

        redirect_to root_path, notice: I18n.t('controllers.sensors.setup.successful')
        return
      end

      render :new, status: :unprocessable_content
    rescue ActiveRecord::RecordNotFound
      redirect_to new_sensors_setup_path, alert: I18n.t('controllers.sensors.setup.sensor_not_found')
    end

    private

    def handle_token_param
      if token_sensor&.pairable?
        session[:setup_sensor_id] = token_sensor.id

        redirect_to new_sensors_setup_path
      else
        toast_now :alert, I18n.t('controllers.sensors.setup.sensor_not_found_or_paired')
      end
    end

    def plant
      @plant ||= Plant.find(sensor_params[:plant_id])
    end

    def sensor
      @sensor ||=
        Sensor.find_by!(id: session[:setup_sensor_id], user_id: Current.user.id, plant_id: nil)
    end

    def sensor_params
      params.require(:sensor)
            .permit(:plant_id, :nickname, :environment, :location, :moisture_threshold)
            .with_defaults(user: Current.user)
    end

    def validation
      @validation ||= Sensors::UidValidator.call(params.require(:uid).to_s.strip)
    end

    def decrypted_token
      @decrypted_token ||=
        Sensor.decrypt_encrypted_token(params[:token], purpose: :sensor_setup) || {}
    end

    def token_sensor
      @token_sensor ||=
        Sensor.find_by(uid: decrypted_token['uid'], secret_key: decrypted_token['secret_key'])
    end

    def session_sensor
      Sensor.find_by(id: session[:setup_sensor_id]) if session[:setup_sensor_id]
    end
  end
end
