class Plant < ApplicationRecord
  ACCESSORS_KEYS = %i[light
                      sowing
                      spread
                      ph_maximum
                      ph_minimum
                      row_spacing
                      bloom_months
                      fruit_months
                      soil_texture
                      growth_months
                      soil_salinity
                      days_to_harvest
                      soil_nutriments
                      minimum_root_depth
                      atmospheric_humidity
                      maximum_precipitation
                      minimum_precipitation].freeze

  MONTHS = Date::MONTHNAMES.compact.map(&:downcase).freeze

  private_constant :ACCESSORS_KEYS

  store_accessor :growth_data, *ACCESSORS_KEYS
  store_accessor :translated_name, :en, :fr, prefix: true

  validates :name, :scientific_name, :trefle_id, :image_url, presence: true
  validates :trefle_id, uniqueness: true
  validates :growth_data, presence: true, if: :valid_growth_data?
  validate :proper_months

  private

  def valid_growth_data?
    ACCESSORS_KEYS.all? { |key| growth_data[key].present? }
  end

  def proper_months
    %i[bloom_months fruit_months growth_months].each do |attr|
      next if public_send(attr).is_a?(Array) && public_send(attr).all? { |month| MONTHS.include?(month) }

      errors.add(attr, :invalid)
    end
  end
end
