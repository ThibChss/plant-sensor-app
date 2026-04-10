module SensorHelper
  def sensor_env_locations
    { indoor: Sensor::INDOOR_LOCATIONS.map(&:to_s), outdoor: Sensor::OUTDOOR_LOCATIONS.map(&:to_s) }
  end

  def sensor_location_labels
    location_label_keys.index_with { t("sensor.location.#{it}") }
  end

  private

  def location_label_keys
    (Sensor::INDOOR_LOCATIONS + Sensor::OUTDOOR_LOCATIONS).map(&:to_s)
  end
end
