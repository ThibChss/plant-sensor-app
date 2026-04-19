module Plants
  class Finder < ApplicationService
    MAX_RESULTS = 10
    JSON_FILE_PATH = Rails.root.join('db', 'plants.json')

    private_constant :MAX_RESULTS, :JSON_FILE_PATH

    def initialize(query: nil)
      @query = query&.downcase&.strip
    end

    def call
      return [] if @query.blank? || @query.length < 3

      search
    end

    private

    def search
      self.class.search_index
          .lazy
          .select { |string, _plant| string.include?(@query) }
          .map { |_string, plant| plant }
          .first(MAX_RESULTS)
    end

    class << self
      def search_index
        @search_index ||= build_search_index
      end

      def reload!
        @search_index = nil
      end

      private

      def build_search_index
        Rails.logger.info "[Plants::Finder] Building search index from disk"

        Oj.load_file(JSON_FILE_PATH.to_s)['plants'].map do |plant|
          [searchable(plant), plant]
        end
      end

      def searchable(plant)
        [
          plant['name'],
          plant['scientific_name'],
          *plant.dig('translated_name', 'en'),
          *plant.dig('translated_name', 'fr')
        ].compact_blank
         .map(&:downcase)
         .join(' ')
      end
    end
  end
end
