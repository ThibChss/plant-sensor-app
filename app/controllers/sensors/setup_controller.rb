module Sensors
  class SetupController < ApplicationController
    rate_limit to: 60, within: 1.minute, only: :validate_uid, name: 'setup-validate-uid',
               by: -> { Current.user.id }

    def new
      if params[:uid].present? && params[:secret_key].present?
        @sensor = Sensor.find_by(uid: params[:uid], secret_key: params[:secret_key])

        if @sensor&.pairable?
          @sensor
        else
          toast_now :alert, I18n.t('controllers.sensors.setup.sensor_not_found_or_paired')

          @sensor = Sensor.new
        end
      else
        @sensor = Sensor.new
      end
    end

    def validate_uid
      render json: Sensors::UidValidator.call(params.require(:uid).to_s.strip)
    end

    def create
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless plant && sensor.update(
          sensor_params.except(:uid, :secret_key, :plant_id).merge(plant:)
        )

        redirect_to root_path, notice: I18n.t('controllers.sensors.setup.successful')
        return
      end

      render :new, status: :unprocessable_content
    rescue ActiveRecord::RecordNotFound
      redirect_to new_sensors_setup_path, alert: I18n.t('controllers.sensors.setup.sensor_not_found')
    end

    private

    def plant
      @plant ||= Plant.find(sensor_params[:plant_id])
    end

    def sensor
      @sensor ||=
        Sensor.find_by!(**sensor_params.slice(:uid, :secret_key).compact_blank, user_id: nil, plant_id: nil)
    end

    def sensor_params
      params.require(:sensor)
            .permit(:uid, :secret_key, :plant_id, :nickname, :environment, :location, :moisture_threshold)
            .with_defaults(user: Current.user)
    end
  end
end
