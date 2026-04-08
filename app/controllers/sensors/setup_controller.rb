module Sensors
  class SetupController < ApplicationController
    rate_limit to: 60, within: 1.minute, only: :validate_uid, name: 'setup-validate-uid',
               by: -> { Current.user.id }

    def new
      @sensor = Sensor.new
    end

    def validate_uid
      render json: Sensors::UidValidator.call(params.require(:uid).to_s.strip)
    end

    def create
      ActiveRecord::Base.transaction do
        @sensor = Sensor.find_by!(uid: sensor_params[:uid], user_id: nil)

        raise ActiveRecord::Rollback unless plant && @sensor.update(
          sensor_params.except(:uid, :plant_id).merge(plant:)
        )

        redirect_to root_path, notice: 'Sensor setup successful'
        return
      end

      render :new, status: :unprocessable_content
    rescue ActiveRecord::RecordNotFound
      redirect_to new_sensors_setup_path, alert: 'Sensor not found'
    end

    private

    def plant
      @plant ||= Plant.find(sensor_params[:plant_id])
    end

    def sensor_params
      params.require(:sensor)
            .permit(:uid, :plant_id, :nickname, :location, :moisture_threshold)
            .with_defaults(user: Current.user)
    end
  end
end
