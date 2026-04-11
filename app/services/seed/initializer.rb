module Seed
  class Initializer < ApplicationService
    class SeedInitializerError < StandardError; end
    TREFLE_TOKEN = ENV["TREFLE_API_TOKEN"]
    TREFLE_URL = ENV["TREFLE_API_URL"]

    PLANT_EMOJIS = ["🌱", "🌿", "🍃", "🍂", "🍁", "🌸", "🌷", "🌺", "🌻", "🌼", "🌹", "🌵", "🌴"].freeze

    private_constant :TREFLE_TOKEN, :TREFLE_URL, :PLANT_EMOJIS

    alias_call :start

    def initialize(env:, from_json: 'true')
      @env = env&.inquiry
      @from_json = ActiveModel::Type::Boolean.new.cast(from_json)
      @trefle_client = TrefleClient.new

      raise SeedInitializerError if @env.nil?
    end

    def call
      clean_database! unless @env.production?

      if @from_json
        generate_new_plants_from_json
      else
        generate_new_plants
      end

      UserPlantsAssociator.call unless @env.production?

      puts "Done ✅"
    end

    private

    def get_all_plants
      @get_all_plants ||= @trefle_client.get_all_plants['data']
    end

    def generate_new_plants
      get_all_plants.each do |plant|
        plant = get_plant(plant["id"])

        find_or_create_plant(plant)
      end
    end

    def generate_new_plants_from_json
      plants_from_json.each do |plant|
        puts "Creating plant: #{plant['name']}"

        Plant.create!(plant)

        puts "Plant created: #{PLANT_EMOJIS.sample} #{plant['name']}"
      end
    end

    def plants_from_json
      JSON.parse(File.read(json_file_path))
    end

    def get_plant(id)
      @trefle_client.get_plant(id)['data']
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
      Plants::GrowthDataFetcher.call(plant)
    end

    def clean_database!
      puts "Cleaning database..."
      DatabaseCleaner.clean_with(:truncation)
      puts "Database cleaned"
    end

    def json_file_path
      @json_file_path ||= @env.production? ? Rails.root.join('db', 'plants.json') : Rails.root.join('db', 'plants_development.json')
    end
  end
end
