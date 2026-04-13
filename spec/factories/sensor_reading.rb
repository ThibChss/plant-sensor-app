FactoryBot.define do
  factory :sensor_reading do
    sensor

    moisture_level_percent { 42 }
    moisture_level_raw { 2675 }
    temperature { 22.5 }
    battery_level { 88 }
    uptime_seconds { 1000 }
  end
end
