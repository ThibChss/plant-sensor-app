def default_growth_data
  {
    light: 10,
    sowing: "autumn",
    spread: {
      cm: 1000
    },
    ph_maximum: 8.0,
    ph_minimum: 6.0,
    row_spacing: nil,
    bloom_months: %w[april may],
    fruit_months: %w[september october],
    soil_texture: 6,
    growth_months: %w[march april may june july august],
    dormancy_months: %w[october november december january february march april],
    soil_salinity: 6,
    days_to_harvest: nil,
    soil_nutriments: 5,
    minimum_root_depth: {
      cm: 150
    },
    atmospheric_humidity: 5,
    maximum_precipitation: {
      mm: 1200
    },
    minimum_precipitation: {
      mm: 400
    },
    max_soil_moisture: {
      indoor: 80,
      outdoor: 80
    },
    min_soil_moisture: {
      indoor: 40,
      outdoor: 40
    },
    watering_frequency: {
      indoor: {
        max_days: 14,
        min_days: 7
      },
      outdoor: {
        max_days: 30,
        min_days: 15
      }
    },
    toxicity: {
      pets: true,
      humans: false
    }
  }
end

FactoryBot.define do
  factory :plant do
    name { 'Evergreen Oak' }
    scientific_name { 'Quercus rotundifolia' }

    trefle_id { Faker::Alphanumeric.alphanumeric(number: 6).upcase }

    image_url { Faker::Internet.url }

    min_temp { -10.0 }
    max_temp { 40.0 }
    ideal_humidity { 4 }

    growth_data { default_growth_data }

    translated_name do
      {
        en: [],
        fr: []
      }
    end

    trait :enriched do
      growth_data { default_growth_data.merge({ _growth_profile_enriched: true }) }
    end
  end
end
