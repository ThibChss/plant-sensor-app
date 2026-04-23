module Sensors
  class SensorReadingsController < ApplicationController
    def index
      @sensor = @current_user.sensors.paired.preload(:plant).find(params[:sensor_id])
      @plant = @sensor.plant

      @range = tracker.param
      @stats = tracker.stats
      @chart_data = tracker.chart_data
    rescue ActiveRecord::RecordNotFound
      redirect_to sensors_path, alert: t('.not_found')
    end

    private

    def tracker
      @tracker ||= Sensors::DataTracker.new(@sensor, params[:range])
    end
  end
end
