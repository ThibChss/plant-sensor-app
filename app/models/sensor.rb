# == Schema Information
#
# Table name: sensors
#
#  id                 :uuid             not null, primary key
#  current_data       :jsonb
#  last_seen_at       :datetime
#  location           :enum             default("indoor"), not null
#  moisture_threshold :integer
#  nickname           :string
#  secret_key         :string           not null
#  uid                :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  plant_id           :uuid             not null
#  user_id            :uuid             not null
#
# Indexes
#
#  index_sensors_on_current_data  (current_data) USING gin
#  index_sensors_on_plant_id      (plant_id)
#  index_sensors_on_secret_key    (secret_key) UNIQUE
#  index_sensors_on_uid           (uid) UNIQUE
#  index_sensors_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (plant_id => plants.id)
#  fk_rails_...  (user_id => users.id)
#
class Sensor < ApplicationRecord
  belongs_to :user
  belongs_to :plant

  enum :location, { indoor: 'indoor', outdoor: 'outdoor' }, default: :indoor, validate: true

  before_validation :generate_secret_key, :generate_uid, on: :create

  encrypts :secret_key, deterministic: true
  attr_readonly :secret_key, :uid

  store_accessor :current_data, :moisture_level, :temperature, :battery_level

  validates :uid, :secret_key, presence: true, uniqueness: { case_sensitive: false }
  validates :user_id, :plant_id, presence: true
  validates :uid, uniqueness: { case_sensitive: false }

  private

  def generate_secret_key
    self.secret_key = "gpm_sk__#{SecureRandom.base58(36)}"
  end

  def generate_uid
    self.uid = "GP-#{SecureRandom.base58(5)}-#{SecureRandom.base58(5)}".upcase
  end
end
