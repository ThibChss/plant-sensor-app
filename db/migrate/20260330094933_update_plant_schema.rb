class UpdatePlantSchema < ActiveRecord::Migration[8.1]
  def up
    change_column_comment :plants, :min_temp, from: nil, to: "Minimum temperature in Celsius"
    change_column_comment :plants, :max_temp, from: nil, to: "Maximum temperature in Celsius"
    change_column_comment :plants, :ideal_humidity, from: nil, to: "Ideal humidity on a scale of 1 to 10, 1 being very dry, 10 being very humid"
    change_column_comment :plants, :growth_data, from: nil, to: "Additional growth data"

    add_index :plants, :trefle_id, unique: true

    change_column_default :plants, :growth_data, from: {}, to: default_growth_data

    add_column :plants, :translated_name, :jsonb, default: { 'en' => [], 'fr' => [] }
  end

  def down
    change_column_comment :plants, :min_temp, from: "Minimum temperature in Celsius", to: nil
    change_column_comment :plants, :max_temp, from: "Maximum temperature in Celsius", to: nil
    change_column_comment :plants, :ideal_humidity, from: "Ideal humidity on a scale of 1 to 10, 1 being very dry, 10 being very humid", to: nil
    change_column_comment :plants, :growth_data, from: "Additional growth data", to: nil

    remove_index :plants, :trefle_id

    change_column_default :plants, :growth_data, from: default_growth_data, to: {}

    remove_column :plants, :translated_name
  end

  private

  def default_growth_data
    {
      light: nil,
      sowing: nil,
      spread: {},
      ph_maximum: nil,
      ph_minimum: nil,
      row_spacing: {},
      bloom_months: [],
      fruit_months: [],
      soil_texture: nil,
      growth_months: [],
      soil_salinity: nil,
      days_to_harvest: nil,
      soil_nutriments: nil,
      minimum_root_depth: {},
      atmospheric_humidity: nil,
      maximum_precipitation: {},
      minimum_precipitation: {}
    }
  end
end
