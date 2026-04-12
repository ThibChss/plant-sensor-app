class SensorsController < ApplicationController
  def index
    @sensors = Current.user.sensors.includes(:plant)

    fresh_when etag: [@sensors, I18n.locale], public: false
  end

  def show
    @plant = sensor&.plant

    fresh_when etag: [@sensor, @plant, I18n.locale], public: false
  rescue ActiveRecord::RecordNotFound
    redirect_to sensors_path, alert: I18n.t('controllers.sensors.show.sensor_not_found')
  end

  private

  def sensor
    @sensor ||= Current.user.sensors.preload(:plant).find(params[:id])
  end
end
