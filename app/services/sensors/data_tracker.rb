module Sensors
  class DataTracker < ApplicationService
    DEFAULT_PARAM = '7d'.freeze
    CACHE_EXPIRATION = 1.hour

    private_constant :DEFAULT_PARAM, :CACHE_EXPIRATION

    attr_reader :param

    def initialize(sensor, param)
      @sensor = sensor
      @param = param || DEFAULT_PARAM
    end

    def stats
      @stats ||=
        Rails.cache.fetch("#{cache_key}_stats", expires_in: CACHE_EXPIRATION) do
          {
            average: stat_for(:average),
            min: stat_for(:minimum),
            max: stat_for(:maximum)
          }
        end
    end

    def chart_data
      @chart_data ||=
        Rails.cache.fetch("#{cache_key}_chart_data", expires_in: CACHE_EXPIRATION) do
          case param
          when '7d'
            group_and_map(:to_time)
          when '30d'
            group_and_map(:to_date)
          when '3m'
            group_and_map(:beginning_of_week, :to_date)
          when '6m'
            group_and_map(:beginning_of_month, :to_date)
          end
        end
    end

    private

    def readings
      @readings ||=
        @sensor.readings
               .where(created_at: range)
               .order(:created_at)
               .select(:moisture_level_percent, :created_at)
    end

    def range
      case param
      when '7d'
        7.days.ago.beginning_of_day..
      when '30d'
        30.days.ago.beginning_of_day..
      when '3m'
        3.months.ago.beginning_of_day..
      when '6m'
        6.months.ago.beginning_of_day..
      end
    end

    def stat_for(key)
      readings.send(key, :moisture_level_percent)&.round(1) || 0
    end

    def group_and_map(*args)
      mapped_readings(group(:created_at, *args))
    end

    def group(*args)
      readings.group_by { chain_send(it, *args).iso8601 }
    end

    def mapped_readings(readings_grouped)
      readings_grouped.map do |date, reading|
        { x: date, y: (reading.sum(&:moisture_level_percent) / reading.size).round(1) }
      end
    end

    def chain_send(object, *args)
      args.reduce(object) { |result, key| result.send(key) }
    end

    def cache_key
      "#{@sensor.cache_key_with_version}_#{@param}_#{Date.current}"
    end
  end
end
