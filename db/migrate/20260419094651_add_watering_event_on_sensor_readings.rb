class AddWateringEventOnSensorReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :sensor_readings, :watering_event, :boolean, default: false, null: false
  end
end
