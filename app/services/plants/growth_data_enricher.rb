module Plants
  class GrowthDataEnricher < ApplicationService
    def initialize(plant_id)
      @plant = Plant.find(plant_id)
    end

    def call
      return response[:success] if @plant.growth_data_complete?
      return response[:fetch_failure] if growth_data.nil?

      enrich_growth_data!

      return response[:error] unless @plant.save

      save_to_json!

      response[:success]
    end

    private

    def enrich_growth_data!
      @plant.min_temp = growth_data.delete('minimum_temperature')
      @plant.max_temp = growth_data.delete('maximum_temperature')
      @plant.ideal_humidity = growth_data.delete('soil_humidity')
      @plant.growth_data = growth_data.merge(Plant::GROWTH_PROFILE_ENRICHED_KEY => true)
    end

    def growth_data
      @growth_data ||= GrowthDataFetcher.call(@plant)
    end

    def save_to_json!
      Seed::CopyDbToJson.call if Rails.env.development?
    end

    def response
      {
        success: {
          ok: true,
          plant_id: @plant.id,
          min_soil_moisture: @plant.min_soil_moisture
        },
        error: {
          ok: false,
          message: @plant.errors.full_messages.to_sentence
        },
        fetch_failure: {
          ok: false,
          message: I18n.t('plants.enrich_growth_data.fetch_failure')
        }
      }
    end
  end
end
