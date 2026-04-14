module Plants
  class Finder < ApplicationService
    MAX_RESULTS = 10

    JSON_FILE_PATH = Rails.root.join('db', 'plants.json')

    CACHE_EXPIRATION = 24.hours

    private_constant :MAX_RESULTS, :JSON_FILE_PATH, :CACHE_EXPIRATION

    def initialize(query: nil)
      @query = query&.downcase&.strip
      @results = Set.new
    end

    def call
      return [] if @query.blank? || @query.length < 3

      search

      @results.to_a
    end

    private

    def search
      plants.each do |plant|
        break if @results.size >= MAX_RESULTS

        @results << plant if plant_matches?(plant)
      end
    end

    def plant_matches?(plant)
      match?(plant, 'name') ||
        match?(plant, 'scientific_name') ||
        array_match?(plant, 'translated_name', 'en') ||
        array_match?(plant, 'translated_name', 'fr')
    end

    def match?(plant, key)
      plant[key]&.downcase&.include?(@query)
    end

    def array_match?(plant, *keys)
      plant.dig(*keys)&.any? { it&.downcase&.include?(@query) }
    end

    def plants
      @plants ||= Rails.cache.fetch(cache_key, expires_in: CACHE_EXPIRATION) do
        Oj.load_file(JSON_FILE_PATH.to_s)['plants']
      end
    end

    def cache_key
      @cache_key ||= "plants_#{File.mtime(JSON_FILE_PATH).to_i}"
    end
  end
end
