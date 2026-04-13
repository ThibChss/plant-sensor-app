class CreateSensorReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :sensor_readings, id: :uuid do |t|
      t.timestamps
      t.references :sensor, foreign_key: true, type: :uuid
      t.float :moisture_level_percent
      t.integer :moisture_level_raw
      t.float :temperature
      t.integer :battery_level
      t.integer :uptime_seconds
    end
  end
end
