module Seed
  class Initializer < ApplicationService
    TREFLE_TOKEN = ENV["TREFLE_API_TOKEN"]
    TREFLE_URL = ENV["TREFLE_API_URL"]

    PLANT_EMOJIS = ["🌱", "🌿", "🍃", "🍂", "🍁", "🌸", "🌷", "🌺", "🌻", "🌼", "🌹", "🌵", "🌴"].freeze

    alias_call :start

    def initialize(page: 1, from_json: false)
      @page = page
      @from_json = from_json
      @json_file = Rails.root.join('db', 'plants.json')
    end

    def call
      clean_database! unless Rails.env.production?

      if @from_json
        generate_new_plants_from_json
      else
        generate_new_plants
      end
    end

    def get_all_plants
      @get_all_plants ||=
        HTTParty.get(
          "#{TREFLE_URL}/plants",
          headers: { "Authorization" => "Token #{TREFLE_TOKEN}" }
        )["data"]
    end

    def generate_new_plants
      get_all_plants.each do |plant|
        plant = get_plant(plant["id"])

        find_or_create_plant(plant)
      end
    end

    def generate_new_plants_from_json
      JSON.parse(File.read(@json_file)).each do |plant|
        puts "Creating plant: #{plant['name']}"

        Plant.create!(plant)

        puts "Plant created: #{PLANT_EMOJIS.sample} #{plant['name']}"
      end
    end

    def get_plant(id)
      HTTParty.get(
        "#{TREFLE_URL}/plants/#{id}",
        headers: { "Authorization" => "Token #{TREFLE_TOKEN}" }
      )["data"]
    end

    def find_or_create_plant(plant)
      name = plant["common_name"] || plant.dig("main_species", "name") || plant["scientific_name"] || plant.dig("main_species", "scientific_name")

      puts "Creating plant: #{name}"

      plant_record = Plant.find_or_initialize_by(trefle_id: plant["id"])

      return unless plant_record.new_record?

      plant_record.assign_attributes(
        name:,
        scientific_name: plant["scientific_name"] || plant.dig("main_species", "scientific_name"),
        image_url: plant["image_url"] || plant.dig("main_species", "image_url"),
        translated_name: {
          en: plant.dig("main_species", "common_names", "en") || [],
          fr: plant.dig("main_species", "common_names", "fr") || []
        }
      )

      puts "Getting growth data for #{plant_record.name}..."

      growth_data = get_growth_data(plant_record)
      return if growth_data.nil?

      plant_record.assign_attributes(
        min_temp: growth_data.delete("minimum_temperature"),
        max_temp: growth_data.delete("maximum_temperature"),
        ideal_humidity: growth_data.delete("soil_humidity"),
        growth_data:
      )

      puts "Growth data added to #{plant_record.name}"
      plant_record.save!

      puts "Plant created: #{PLANT_EMOJIS.sample} #{plant_record.name}"
    end

    def get_growth_data(plant)
      GeminiCompleter.call(plant)
    end

    def clean_database!
      puts "Cleaning database..."
      DatabaseCleaner.clean_with(:truncation)
      puts "Database cleaned"
    end
  end
end
