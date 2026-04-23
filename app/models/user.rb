# == Schema Information
#
# Table name: users
#
#  id                         :uuid             not null, primary key
#  email_address              :string           not null
#  first_name                 :string           not null
#  last_name                  :string           not null
#  last_seen_at               :datetime
#  locale                     :string           default("fr"), not null
#  password_digest            :string           not null
#  push_notifications_enabled :boolean          default(TRUE), not null
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#  index_users_on_last_seen_at   (last_seen_at)
#
class User < ApplicationRecord
  has_secure_password

  has_many :sessions, dependent: :destroy
  has_many :sensors, dependent: :destroy
  has_many :plants, through: :sensors
  has_many :push_subscriptions, dependent: :destroy

  validates :first_name, :last_name, presence: true
  validates :password, presence: true, if: -> { new_record? }
  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }

  normalizes :email_address, :locale, with: -> { it.to_s.strip.downcase }

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0].upcase}#{last_name[0].upcase}"
  end

  def notify(message:, notification_type:, flash_type: :notice, notifiable: nil, data: {})
    Notifications::Deliverer.notify!(user: self, message:, notification_type:, flash_type:, notifiable:, data:)
  end

  def active?
    last_seen_at > 2.minutes.ago
  end
end
