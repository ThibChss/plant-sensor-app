module Seed
  class GenerateJsonPlantsProd < ApplicationService
    PAUSE_BETWEEN_REQUESTS = 1.2
    BASE_SLEEP_TIME = 5
    LIMIT_EXCEEDED_SLEEP_TIME = 60
    RESPONSE_CODES_TO_RETRY = {
      ok: '200',
      rate_limit_exceeded: '429',
      not_found: '404'
    }.freeze

    private_constant :PAUSE_BETWEEN_REQUESTS, :RESPONSE_CODES_TO_RETRY, :BASE_SLEEP_TIME, :LIMIT_EXCEEDED_SLEEP_TIME

    alias_call :start

    def initialize
      @started_at = Time.now
      @file_path = Rails.root.join('db', 'plants.json')
      @trefle_client = TrefleClient.new
      @plants = load_existing_plants["plants"] || []
      @page = load_existing_plants.dig("metadata", "last_page") || 1
      @total_to_fetch = load_existing_plants.dig("metadata", "total")
      @finished = false
    end

    def call
      log("🚀 Reprise du scan à la page #{@page} (#{@plants.size} plantes déjà en base)")

      get_all_plants

      log("✨ Fin du scan. #{@plants.size} plantes au total.")
    end

    private

    def get_all_plants
      loop do
        log("Getting plants page #{@page}...")
        plants = with_retry("page #{@page}") do
          @trefle_client.get_all_plants(page: @page, params: { filter_not: { common_name: 'null' } })
        end['data']

        @total_to_fetch ||= plants.dig("meta", "total")

        handle_on_complete and break if plants.blank?

        @plants.concat(fetch_datas(plants))
        @page += 1

        save_to_json
        show_progress
      end
    end

    def handle_on_complete
      @finished = true

      log("No plants found on page #{@page}, finishing...")
      save_to_json
      log("Finished, #{@plants.size} plants saved to JSON")

      @finished
    end

    def fetch_datas(plants)
      plants.map do |plant|
        log("Fetching data for plant #{plant['id']}...")

        plant_data(get_plant(plant["id"]))
      end
    end

    def get_plant(id)
      with_retry("plant #{id}", plant_id: id) { @trefle_client.get_plant(id) }["data"]
    end

    def plant_data(plant)
      {
        trefle_id: plant["id"],
        name: plant["common_name"],
        scientific_name: plant["scientific_name"],
        image_url: plant["image_url"],
        translated_name: {
          en: plant.dig("main_species", "common_names", "en") || [],
          fr: plant.dig("main_species", "common_names", "fr") || []
        }
      }
    end

    def with_retry(context, plant_id: nil, is_retry: false, &)
      log("🔄 Retrying to get data for plant #{plant_id}...") if plant_id.present? && is_retry

      @response = yield

      return handle_if_no_retry if no_retry_needed?

      log("🛑 Error getting data for #{context}: #{@response.response.code} #{@response.response.message}")

      handle_if_retry

      with_retry(context, plant_id:, is_retry: true, &)
    end

    def handle_if_no_retry
      ok? ? @response : {}
    end

    def handle_if_retry
      if @response.response.code == RESPONSE_CODES_TO_RETRY[:rate_limit_exceeded]
        log("💤 Rate limit exceeded, waiting 60 seconds...")

        sleep LIMIT_EXCEEDED_SLEEP_TIME
      else
        sleep BASE_SLEEP_TIME
      end
    end

    def no_retry_needed?
      ok? || @response.response.code == RESPONSE_CODES_TO_RETRY[:not_found]
    end

    def ok?
      @response.response.code == RESPONSE_CODES_TO_RETRY[:ok]
    end

    def log(message, elapsed: Time.current - @started_at)
      puts "<#{Time.at(elapsed).utc.strftime('%H:%M:%S')}> #{message}"
    end

    def show_progress
      return unless @total_to_fetch

      percent = ((@plants.size.to_f / @total_to_fetch) * 100).round(2)
      remaining_count = @total_to_fetch - @plants.size

      total_seconds = (remaining_count * PAUSE_BETWEEN_REQUESTS).to_i
      hours = total_seconds / 3600
      minutes = (total_seconds % 3600) / 60

      time_str = hours.positive? ? "#{hours}h #{minutes}min" : "#{minutes}min"

      log("📊 Progression : #{percent}% (#{@plants.size}/#{@total_to_fetch}) | Estimation restante : ~#{time_str}")
    end

    def load_existing_plants
      return {} unless File.exist?(@file_path)

      JSON.parse(File.read(@file_path))
    end

    def output
      {
        metadata: {
          last_page: @page,
          total_count: @plants.size,
          last_updated_at: Time.current,
          status: @finished ? "finished" : "in_progress",
          total: @total_to_fetch
        },
        plants: @plants
      }
    end

    def save_to_json
      File.write(@file_path, JSON.pretty_generate(output))
    end
  end
end
