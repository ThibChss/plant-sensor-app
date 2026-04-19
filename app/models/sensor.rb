# == Schema Information
#
# Table name: sensors
#
#  id                 :uuid             not null, primary key
#  current_data       :jsonb
#  environment        :enum             default("indoor"), not null
#  last_seen_at       :datetime
#  location           :string
#  moisture_threshold :integer
#  nickname           :string
#  pairing_code       :string
#  secret_key         :string           not null
#  uid                :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  plant_id           :uuid
#  user_id            :uuid
#
# Indexes
#
#  index_sensors_on_current_data  (current_data) USING gin
#  index_sensors_on_plant_id      (plant_id)
#  index_sensors_on_secret_key    (secret_key) UNIQUE WHERE (secret_key IS NOT NULL)
#  index_sensors_on_uid           (uid) UNIQUE WHERE (uid IS NOT NULL)
#  index_sensors_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (plant_id => plants.id)
#  fk_rails_...  (user_id => users.id)
#
class Sensor < ApplicationRecord
  include Broadcaster::Sensor

  DEFAULT_MOISTURE_THRESHOLD = 25

  CURRENT_DATA_KEYS = %i[
    moisture_level_percent
    moisture_level_raw
    temperature
    battery_level
    uptime_seconds
  ].freeze

  INDOOR_LOCATIONS = %i[
    living_room
    kitchen
    bedroom
    bathroom
    office
    dining_room
    entrance
    corridor
  ].freeze

  OUTDOOR_LOCATIONS = %i[
    garden
    terrace
    balcony
    porch
    patio
    yard
    greenhouse
  ].freeze

  UID_REGEXP, SECRET_KEY_REGEXP, PAIRING_CODE_REGEXP = [
    /\AGP-[A-Z0-9]{5}-[A-Z0-9]{5}\z/,
    /\Agpm_sk__[A-Za-z0-9]{36}\z/,
    /\A\d{8}\z/
  ].freeze

  private_constant :CURRENT_DATA_KEYS

  belongs_to :user, optional: true, touch: true
  belongs_to :plant, optional: true, touch: true

  has_many :readings, class_name: :SensorReading, dependent: :destroy

  enum :environment, { indoor: 'indoor', outdoor: 'outdoor' }, default: :indoor, validate: true

  before_validation :generate_keys, on: :create

  encrypts :secret_key, deterministic: true
  attr_readonly :secret_key, :uid

  store_accessor :current_data, *CURRENT_DATA_KEYS

  validates :uid, :secret_key, presence: true, uniqueness: { case_sensitive: false }, if: -> { new_record? }
  validates :secret_key, format: { with: SECRET_KEY_REGEXP }, if: -> { new_record? }
  validates :uid, format: { with: UID_REGEXP }, if: -> { new_record? }
  validates :user_id, :plant_id, presence: true, on: :update, unless: :pairable?
  validates :pairing_code, presence: true, length: { is: 8 }, format: { with: PAIRING_CODE_REGEXP }, if: -> { new_record? }
  validate :location_matches_environment, on: :update

  after_update :generate_reading, if: :saved_change_to_current_data?

  scope :thirsty, lambda {
    where("current_data ? 'moisture_level_percent'")
      .where("(current_data->>'moisture_level_percent')::numeric < moisture_threshold")
  }

  scope :paired, -> { where.not(plant_id: nil) }

  def thirsty?
    return false unless moisture_level_present?

    moisture_level_percent.to_f < (moisture_threshold.presence || DEFAULT_MOISTURE_THRESHOLD)
  end

  def moisture_level_present?
    moisture_level_percent.present?
  end

  def pairable?
    plant_id.blank?
  end

  def qr_code
    RQRCode::QRCode.new(
      Rails.application.routes.url_helpers.new_sensors_setup_url(uid:, secret_key:),
      level: :m
    )
  end

  private

  def generate_keys
    generate_secret_key
    generate_uid
    generate_pairing_code
  end

  def generate_secret_key
    self.secret_key = "gpm_sk__#{SecureRandom.base58(36)}" if secret_key.blank?
  end

  def generate_uid
    self.uid = "GP-#{SecureRandom.base58(5)}-#{SecureRandom.base58(5)}".upcase if uid.blank?
  end

  def generate_pairing_code
    self.pairing_code = format('%08d', SecureRandom.random_number(10**8)) if pairing_code.blank?
  end

  def location_matches_environment
    return if location.blank? || "Sensor::#{environment.upcase}_LOCATIONS".constantize.include?(location.to_sym)

    errors.add(:location, :invalid)
  end

  def generate_reading
    return if current_data.values.compact_blank.empty?

    readings.create!(current_data)
  end
end
