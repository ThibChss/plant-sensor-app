module Plants
  class GrowthDataFetcher < ApplicationService
    SCHEMA_PATH = Rails.root.join('config/schemas/gemini_plant_growth_schema.json').freeze
    RETRY_DELAYS = [1, 2, 4, 8, 16].freeze

    private_constant :SCHEMA_PATH, :RETRY_DELAYS

    def self.schema
      @schema ||= JSON.parse(File.read(SCHEMA_PATH))
    end

    def initialize(plant)
      @plant = plant
      @gemini_client = GeminiClient.new.client
      @retries = 0
    end

    def call
      return nil if unparsed_response_with_retries.blank?

      JSON.parse(unparsed_response_with_retries)
    rescue JSON::ParserError
      Rails.logger.error("Error parsing Gemini response: #{unparsed_response_with_retries}")
      nil
    end

    private

    def response
      @gemini_client.generate_content(
        {
          contents: {
            role: 'user',
            parts: {
              text: prompt
            }
          },
          generationConfig: {
            response_mime_type: "application/json",
            response_schema: self.class.schema
          }
        }
      )
    end

    def unparsed_response
      response.dig('candidates', 0, "content", "parts", 0, "text")
    end

    def unparsed_response_with_retries
      @unparsed_response_with_retries ||=
        begin
          unparsed_response
        rescue Faraday::TooManyRequestsError => e
          raise e unless @retries < RETRY_DELAYS.size

          Rails.logger.error("[Gemini] Rate limit exceeded or network error. Retrying in #{RETRY_DELAYS[@retries]}s... (Attempt #{@retries + 1})")
          sleep RETRY_DELAYS[@retries]

          @retries += 1

          retry
        end
    end

    def prompt
      <<~PROMPT
        Provide accurate horticultural cultivation parameters for: #{@plant.scientific_name} #{common_name_context}.
        Base values on species-level literature.

        Rules:
        - Tropical/subtropical houseplants (e.g. Monstera, Peperomia, Ficus): treat as INDOOR. growth_months = 12 months unless indoor dormancy is documented. bloom_months indoor typical (often empty).
        - Temperate species: temperate Northern Hemisphere climate.
        - Soil moisture/watering: potting mix for indoor, garden soil for outdoor.
        - Months: lowercase English names (e.g., "january").
        - Sowing: "Spring", "Autumn", "Winter", "Summer", or null.
        - Scales: integers as specified in schema.
      PROMPT
    end

    def common_name_context
      return '' if @plant.name.blank?

      "(Common name: #{@plant.name})"
    end
  end
end
