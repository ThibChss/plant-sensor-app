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
        Agis en tant qu'expert botaniste et base de données horticole.
        Ta mission est de fournir les paramètres de culture précis pour la plante suivante : #{@plant.scientific_name}.

        Tu dois impérativement répondre au format JSON pur, sans texte avant ou après.
        Respecte scrupuleusement les types de données (integers pour les échelles, arrays pour les mois, floats pour le pH).

        Voici la structure attendue :
        {
          "french_name": string (Ex: 'Chêne vert' ou nil si inconnu),
          "sowing": string (Ex: 'Spring' ou 'Autumn'),
          "days_to_harvest": integer ou nil,
          "row_spacing": {"cm": integer},
          "spread": {"cm": integer},
          "ph_maximum": float,
          "ph_minimum": float,
          "light": integer (échelle 1 à 10, 10 étant plein soleil),
          "atmospheric_humidity": integer (échelle 1 à 10, 10 étant très humide),
          "min_soil_moisture": {
            "indoor": integer (échelle 1 à 100),
            "outdoor": integer (échelle 1 à 100)
          },
          "max_soil_moisture": {
            "indoor": integer (échelle 1 à 100),
            "outdoor": integer (échelle 1 à 100)
          },
          "growth_months": [strings en anglais minuscules ou array vide si inconnue],
          "bloom_months": [strings en anglais minuscules ou array vide si inconnue],
          "fruit_months": [strings en anglais minuscules ou array vide si inconnue],
          "minimum_precipitation": {"mm": integer},
          "maximum_precipitation": {"mm": integer},
          "minimum_root_depth": {"cm": integer},
          "minimum_temperature": float,
          "maximum_temperature": float,
          "soil_nutriments": integer (échelle 1 à 10),
          "soil_salinity": integer (échelle 1 à 10),
          "soil_texture": integer (échelle 1 à 10 : 1=Sableux, 10=Argileux),
          "soil_humidity": integer (échelle 1 à 10, 1 étant très sec, 10 saturé d'eau)
        }

        Si une information est inconnue, renvoie nil pour cette clé.
      PROMPT
    end

    def unparsed_response_with_retries
      @unparsed_response_with_retries ||=
        begin
          unparsed_response
        rescue Faraday::TooManyRequestsError => e
          raise e unless @retries < RETRY_DELAYS.size

          Rails.logger.error("[Gemini] Limite atteinte ou erreur réseau. Nouvel essai dans #{RETRY_DELAYS[@retries]}s... (Tentative #{@retries + 1})")
          sleep RETRY_DELAYS[@retries]

          @retries += 1

          retry
        end
    end
  end
end
