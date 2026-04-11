class ChangeDefaultCurrentDataSensor < ActiveRecord::Migration[8.1]
  def change
    change_column_default :sensors, :current_data, from: {
      moisture_level: nil,
      temperature: nil,
      battery_level: nil
    }, to: {
      moisture_level_percent: nil,
      moisture_level_raw: nil,
      temperature: nil,
      battery_level: nil,
      uptime_seconds: nil
    }
  end
end
