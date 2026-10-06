require 'csv'

module Plants
  class MiFloraDbFetcher < ApplicationService
    CSV_FILE_PATH = Rails.root.join('db', 'mi_flora_db_dump.csv')
    CSV_OPTIONS = {
      headers: true,
      header_converters: :symbol,
      encoding: 'bom|utf-8'
    }

    private_constant :CSV_FILE_PATH, :CSV_OPTIONS

    class << self
      def find(scientific_name)
        return {} if scientific_name.blank?

        generate_lookup if index.empty?

        index[scientific_name.downcase.squish]
      end

      private

      def generate_lookup
        CSV.foreach(CSV_FILE_PATH, **CSV_OPTIONS) do |row|
          normalized_scientific_name = (row[:pid] || row[:display_pid]).gsub(/'[^']*'/, '').downcase.squish

          next if normalized_scientific_name.blank? || index.key?(normalized_scientific_name)

          index[normalized_scientific_name] = {
            minimum_temperature: row[:min_temp]&.to_f,
            maximum_temperature: row[:max_temp]&.to_f,
            soil_humidity: ideal_humidity(row[:min_env_humid], row[:max_env_humid]),
            min_soil_moisture: row[:min_soil_moist]&.to_f,
            max_soil_moisture: row[:max_soil_moist]&.to_f,
            light_lux: {
              min: row[:min_light_lux]&.to_f,
              max: row[:max_light_lux]&.to_f
            },
            from_mi_flora_db: true
          }.deep_stringify_keys!
        end
      end

      def index
        @index ||= {}
      end

      def ideal_humidity(min, max)
        return nil if min.blank? || max.blank?

        (((min.to_f + max.to_f) / 2) / 10).round.clamp(1, 10)
      end
    end
  end
end
