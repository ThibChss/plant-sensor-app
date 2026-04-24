# == Schema Information
#
# Table name: sensor_readings
#
#  id                     :uuid             not null, primary key
#  battery_level          :integer
#  battery_level_percent  :integer
#  battery_level_raw      :integer
#  moisture_level_percent :float
#  moisture_level_raw     :integer
#  temperature            :float
#  uptime_seconds         :integer
#  watering_event         :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  sensor_id              :uuid
#
# Indexes
#
#  index_sensor_readings_on_sensor_id                 (sensor_id)
#  index_sensor_readings_on_sensor_id_and_created_at  (sensor_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (sensor_id => sensors.id)
#
class SensorReading < ApplicationRecord
  belongs_to :sensor
end
