# == Schema Information
#
# Table name: sensor_readings
#
#  id                     :uuid             not null, primary key
#  battery_level          :integer
#  moisture_level_percent :float
#  moisture_level_raw     :integer
#  temperature            :float
#  uptime_seconds         :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  sensor_id              :uuid
#
# Indexes
#
#  index_sensor_readings_on_sensor_id  (sensor_id)
#
# Foreign Keys
#
#  fk_rails_...  (sensor_id => sensors.id)
#
class SensorReading < ApplicationRecord
  belongs_to :sensor
end
