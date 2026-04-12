class SensorsController < ApplicationController
  def index
    @sensors = Current.user.sensors.includes(:plant)
  end

  def show
    @sensor = Current.user.sensors.preload(:plant).find(params[:id])
    @plant = @sensor&.plant
  rescue ActiveRecord::RecordNotFound
    redirect_to sensors_path, alert: I18n.t('controllers.sensors.show.sensor_not_found')
  end
end
