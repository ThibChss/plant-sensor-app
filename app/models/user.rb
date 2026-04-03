# == Schema Information
#
# Table name: users
#
#  id              :uuid             not null, primary key
#  email_address   :string           not null
#  first_name      :string           not null
#  last_name       :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  validates :first_name, :last_name, :password, presence: true
  validates :email_address, presence: true, uniqueness: true,
                            format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email_address, with: -> { it.strip.downcase }
end
