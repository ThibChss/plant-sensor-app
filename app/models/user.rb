class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :first_name, :last_name, :password, presence: true
  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: -> { it.strip.downcase }
end
