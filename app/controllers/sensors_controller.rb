class SensorsController < ApplicationController
  def index
    @sensors = Current.user.sensors.includes(:plant)
    @thirsty_sensors = @sensors.thirsty
  end
end
