# == Schema Information
#
# Table name: plants
#
#  id                                                                                          :uuid             not null, primary key
#  growth_data(Additional growth data)                                                         :jsonb
#  ideal_humidity(Ideal humidity on a scale of 1 to 10, 1 being very dry, 10 being very humid) :integer
#  image_url                                                                                   :string
#  max_temp(Maximum temperature in Celsius)                                                    :float
#  min_temp(Minimum temperature in Celsius)                                                    :float
#  name                                                                                        :string
#  scientific_name                                                                             :string
#  translated_name                                                                             :jsonb
#  created_at                                                                                  :datetime         not null
#  updated_at                                                                                  :datetime         not null
#  trefle_id                                                                                   :string
#
# Indexes
#
#  index_plants_on_trefle_id  (trefle_id) UNIQUE
#
class Plant < ApplicationRecord
  has_many :sensors, dependent: :destroy

  ACCESSORS_KEYS = %i[
    light
    sowing
    days_to_harvest
    row_spacing
    spread
    ph_maximum
    ph_minimum
    light
    atmospheric_humidity
    min_soil_moisture
    max_soil_moisture
    growth_months
    bloom_months
    dormancy_months
    fruit_months
    minimum_precipitation
    maximum_precipitation
    minimum_root_depth
    soil_nutriments
    soil_salinity
    soil_texture
    soil_humidity
    toxicity
    watering_frequency
  ].freeze

  MONTHS = Date::MONTHNAMES.compact.map(&:downcase).freeze

  GROWTH_PROFILE_ENRICHED_KEY = '_growth_profile_enriched'

  private_constant :ACCESSORS_KEYS

  store_accessor :growth_data, *ACCESSORS_KEYS
  store_accessor :translated_name, :en, :fr, prefix: true

  validates :name, :scientific_name, :trefle_id, :image_url, presence: true
  validates :trefle_id, uniqueness: true
  validates :growth_data, presence: true, if: :valid_growth_data?
  validate :proper_months

  after_save :remove_duplicate_names

  def growth_data_complete?
    ActiveModel::Type::Boolean.new.cast(growth_data[GROWTH_PROFILE_ENRICHED_KEY]) || false
  end

  def display_name
    (translated_name[I18n.locale.to_s]&.first&.presence || name).titleize
  end

  def growth_period?(month = MONTHS[Date.current.month - 1])
    growth_months.include?(month)
  end

  private

  def valid_growth_data?
    ACCESSORS_KEYS.all? { growth_data[it].present? }
  end

  def proper_months
    %i[bloom_months fruit_months growth_months dormancy_months].each do
      next if public_send(it).is_a?(Array) &&
              (public_send(it).empty? || public_send(it).all? { |month| MONTHS.include?(month.downcase) })

      errors.add(it, :invalid)
    end
  end

  def remove_duplicate_names
    update_columns(
      translated_name: {
        'fr' => translated_name_fr.uniq.compact_blank,
        'en' => translated_name_en.uniq.compact_blank
      }
    )
  end
end
