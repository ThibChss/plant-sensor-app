# frozen_string_literal: true

module Sensors
  class DataTracker < ApplicationService
    DEFAULT_PARAM = '7d'
    CACHE_EXPIRATION = 1.hour

    RANGES = {
      '7d' => { interval: 7.days, truncate_to: nil },
      '30d' => { interval: 30.days, truncate_to: 'day' },
      '3m' => { interval: 3.months, truncate_to: 'week'  },
      '6m' => { interval: 6.months, truncate_to: 'month' }
    }.freeze

    private_constant :DEFAULT_PARAM, :CACHE_EXPIRATION, :RANGES

    attr_reader :param

    def initialize(sensor, param)
      @sensor = sensor
      @param  = param || DEFAULT_PARAM
      @range = RANGES[@param]
    end

    def stats
      @stats ||= Rails.cache.fetch("#{cache_key}_stats", expires_in: CACHE_EXPIRATION) do
        {
          average: fetched_stats['average'].to_f,
          min: fetched_stats['min'].to_f,
          max: fetched_stats['max'].to_f
        }
      end
    end

    def chart_data
      @chart_data ||= Rails.cache.fetch("#{cache_key}_chart_data", expires_in: CACHE_EXPIRATION) do
        if @range[:truncate_to]
          aggregated_chart_data(@range[:truncate_to])
        else
          individual_readings_chart_data
        end
      end
    end

    private

    def fetched_stats
      readings_scope
        .unscope(:order)
        .select(
          'ROUND(AVG(moisture_level_percent)::numeric, 1) AS average',
          'ROUND(MIN(moisture_level_percent)::numeric, 1) AS min',
          'ROUND(MAX(moisture_level_percent)::numeric, 1) AS max'
        )
        .take
    end

    def readings_scope
      @readings_scope ||= SensorReading.where(sensor_id: @sensor.id, created_at: range_start..)
    end

    def range_start
      @range_start ||= @range[:interval].ago.beginning_of_day
    end

    def individual_readings_chart_data
      readings_scope
        .order(:created_at)
        .pluck(:created_at, :moisture_level_percent)
        .map do |created_at, moisture|
          { x: created_at.iso8601, y: moisture.round(1) }
        end
    end

    def aggregated_chart_data(truncate_to)
      readings_scope
        .unscope(:order)
        .select(
          "DATE_TRUNC('#{truncate_to}', created_at) AS timestamp",
          'ROUND(AVG(moisture_level_percent)::numeric, 1) AS average'
        )
        .group("DATE_TRUNC('#{truncate_to}', created_at)")
        .order('timestamp ASC')
        .map do |row|
          { x: row['timestamp'].to_date.iso8601, y: row['average'].to_f }
        end
    end

    def cache_key
      "#{@sensor.cache_key_with_version}_#{@param}_#{Date.current}"
    end
  end
end
