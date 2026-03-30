module Seed
  class Initializer < ApplicationService
    TREFLE_TOKEN = ENV["TREFLE_API_TOKEN"]
    TREFLE_URL = ENV["TREFLE_API_URL"]

    PLANT_EMOJIS = ["🌱", "🌿", "🍃", "🍂", "🍁", "🌸", "🌷", "🌺", "🌻", "🌼", "🌹", "🌵", "🌴"].freeze

    alias_call :start

    def initialize(page = 1)
      @page = page
    end

    def call
      clean_database!

      iterate_plants
    end

    def get_all_plants
      @get_all_plants ||=
        HTTParty.get(
          "#{TREFLE_URL}/plants",
          headers: { "Authorization" => "Token #{TREFLE_TOKEN}" }
        )["data"]
    end

    def iterate_plants
      get_all_plants.each do |plant|
        plant = get_plant(plant["id"])
        plant_record = find_or_create_plant(plant)

        update_with_growth_data(plant_record)
      end
    end

    def get_plant(id)
      HTTParty.get(
        "#{TREFLE_URL}/plants/#{id}",
        headers: { "Authorization" => "Token #{TREFLE_TOKEN}" }
      )["data"]
    end

    def find_or_create_plant(plant)
      plant_record = Plant.find_or_initialize_by(trefle_id: plant["id"])

      return unless plant_record.new_record?

      plant_record.assign_attributes(
        name: plant.dig("main_species", "common_names", "fr").first || plant["scientific_name"] || plant.dig("main_species", "scientific_name"),
        scientific_name: plant["scientific_name"] || plant.dig("main_species", "scientific_name"),
        image_url: plant["image_url"] || plant.dig("main_species", "image_url")
      )

      plant_record.save!

      puts "Plant created: #{PLANT_EMOJIS.sample} #{plant_record.name}"
      plant_record
    end

    def get_growth_data(plant)
      GeminiCompleter.call(plant)
    end

    def update_with_growth_data(plant)
      puts "Getting growth data for #{plant.name}..."
      growth_data = get_growth_data(plant)

      return if growth_data.nil?

      plant.update!(
        min_temp: growth_data.delete("minimum_temperature"),
        max_temp: growth_data.delete("maximum_temperature"),
        ideal_humidity: growth_data.delete("soil_humidity"),
        growth_data:
      )

      puts "Growth data updated: #{PLANT_EMOJIS.sample} #{plant.name}"
    end

    def clean_database!
      puts "Cleaning database..."
      DatabaseCleaner.clean_with(:truncation)
      puts "Database cleaned"
    end
  end
end
