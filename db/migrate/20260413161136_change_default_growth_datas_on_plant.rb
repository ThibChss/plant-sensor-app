class ChangeDefaultGrowthDatasOnPlant < ActiveRecord::Migration[8.1]
  def change
    change_column_default :plants, :growth_data, from: old_default_growth_data, to: new_default_growth_data
  end

  private

  def old_default_growth_data
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
      minimum_precipitation: {},
      max_soil_moisture: {
        indoor: nil,
        outdoor: nil
      },
      min_soil_moisture: {
        indoor: nil,
        outdoor: nil
      }
    }
  end

  def new_default_growth_data
    old_default_growth_data.merge(
      dormancy_months: [],
      watering_frequency: {
        indoor: {
          max_days: nil,
          min_days: nil
        },
        outdoor: {
          max_days: nil,
          min_days: nil
        }
      },
      toxicity: {
        pets: nil,
        humans: nil
      }
    )
  end
end
