class AddBatteryDatasOnSensorReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :sensor_readings, :battery_level_raw, :integer
    add_column :sensor_readings, :battery_level_percent, :integer
  end
end
