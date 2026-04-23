# frozen_string_literal: true

class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  def change
    # Composite index for time-range queries scoped to a sensor (DataTracker, charts, stats)
    add_index :sensor_readings, %i[sensor_id created_at],
              name: 'index_sensor_readings_on_sensor_id_and_created_at'

    # GIN index for JSONB containment queries on notifications.data
    add_index :notifications, :data,
              using: :gin,
              name: 'index_notifications_on_data'
  end
end
