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

  store_accessor :growth_data, *ACCESSORS_KEYS
  store_accessor :translated_name, :en, :fr, prefix: true

  validates :name, :scientific_name, :trefle_id, :image_url, :min_temp, :max_temp, :ideal_humidity, presence: true
  validates :trefle_id, uniqueness: true
  validates :growth_data, presence: true, if: :valid_growth_data?
  validate :valid_monthes?

  private

  def valid_growth_data?
    ACCESSORS_KEYS.all? { |key| growth_data[key].present? }
  end

  def valid_monthes?
    %i[bloom_months fruit_months growth_months].all? do |data|
      public_send(data).is_a?(Array) && public_send(data).all? { |month| monthes.include?(month) }
    end
  end

  def monthes
    Date::MONTHNAMES.compact.map(&:downcase).freeze
  end
end
