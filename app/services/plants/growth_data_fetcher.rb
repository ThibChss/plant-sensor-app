module Plants
  class GrowthDataFetcher < ApplicationService
    RETRY_DELAYS = [1, 2, 4, 8, 16].freeze

    def initialize(plant)
      @plant = plant
      @gemini_client = GeminiClient.new.client
      @retries = 0
    end

    def call
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
            response_mime_type: "application/json"
          }
        }
      )
    end

    def unparsed_response
      response.dig('candidates', 0, "content", "parts", 0, "text")
    end

    def prompt
      <<~PROMPT
        You are an expert botanist and horticultural database with deep knowledge of plant physiology,
        cultivation requirements, and care guidelines.
        Your task is to provide precise growing parameters for the following plant:
        #{@plant.scientific_name} #{common_name_context}.

        Base your response on established horticultural literature and scientific consensus.
        Prioritize species-specific data over genus-level generalizations.
        If the plant is a cultivated variety, base values on the species type unless the variety is well-documented.

        IMPORTANT — Climate context:
        - If the plant is a tropical or subtropical species (e.g. Monstera, Peperomia, Ficus, Philodendron),
          treat it as an INDOOR houseplant. growth_months must be all 12 months unless it has a documented
          indoor dormancy. bloom_months should reflect typical indoor behaviour (often empty or unpredictable).
        - Otherwise, provide values for temperate Northern Hemisphere climate conditions.

        For soil moisture and watering frequency, assume:
          - Standard potting mix for indoor
          - Garden soil for outdoor
        For toxicity, consider ingestion by mammals. Mark as true only if there is documented evidence of toxicity.
        Do not confuse soil_humidity (natural habitat preference) with min/max_soil_moisture (irrigation thresholds).

        You MUST respond with pure JSON only — no text before or after.
        Strictly respect data types:
          - Integers for scales
          - Arrays for months
          - Floats for pH
        For unknown values, return null.
        All month arrays must use lowercase English month names (e.g., "january", "february").
        "sowing" must be one of: "Spring", "Autumn", "Winter", "Summer", or null.

        Return this exact structure:

        {
          "french_name": string (Example: 'Chêne vert' or null if unknown),
          "sowing": string (Example: 'Spring' or 'Autumn'),
          "days_to_harvest": integer or null,
          "row_spacing": {
            "cm": integer
          },
          "spread": {
            "cm": integer
          },
          "ph_maximum": float,
          "ph_minimum": float,
          "light": integer (scale 1 to 10, 10 being full sun),
          "atmospheric_humidity": integer (scale 1 to 10, 10 being very humid),
          "min_soil_moisture": {
            "indoor": integer (scale 1 to 100),
            "outdoor": integer (scale 1 to 100)
          },
          "max_soil_moisture": {
            "indoor": integer (scale 1 to 100),
            "outdoor": integer (scale 1 to 100)
          },
          "growth_months": [lowercase English month names or empty array if unknown],
          "bloom_months": [lowercase English month names or empty array if unknown],
          "dormancy_months": [lowercase English month names or empty array if unknown],
          "fruit_months": [lowercase English month names or empty array if unknown],
          "minimum_precipitation": {
            "mm": integer
          },
          "maximum_precipitation": {
            "mm": integer
          },
          "minimum_root_depth": {
            "cm": integer
          },
          "minimum_temperature": float,
          "maximum_temperature": float,
          "soil_nutriments": integer (scale 1 to 10),
          "soil_salinity": integer (scale 1 to 10),
          "soil_texture": integer (scale 1 to 10 : 1=Sandy, 10=Clayey),
          "soil_humidity": integer (scale 1 to 10, 1 being very dry, 10 being saturated with water),
          "toxicity": {
            "pets": boolean,
            "humans": boolean
          },
          "watering_frequency": {
            "indoor": {
              "min_days": integer,
              "max_days": integer
            },
            "outdoor": {
              "min_days": integer,
              "max_days": integer
            }
          }
        }
      PROMPT
    end

    def common_name_context
      return '' if @plant.name.blank?

      "(Common name: #{@plant.name})"
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
  end
end
