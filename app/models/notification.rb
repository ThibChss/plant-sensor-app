# == Schema Information
#
# Table name: notifications
#
#  id              :uuid             not null, primary key
#  data            :jsonb            not null
#  notifiable_type :string
#  read_at         :datetime
#  type            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  notifiable_id   :uuid
#  user_id         :uuid             not null
#
# Indexes
#
#  index_notifications_on_data                    (data) USING gin
#  index_notifications_on_notifiable              (notifiable_type,notifiable_id)
#  index_notifications_on_user_id                 (user_id)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at)
#  index_notifications_on_user_id_and_read_at     (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :notifiable, polymorphic: true, optional: true

  validates :type, presence: true

  scope :unread, -> { where(read_at: nil) }

  store_accessor :data, :message

  before_validation :set_message, on: :create

  def read?
    read_at.present?
  end

  def unread?
    !read?
  end

  def mark_as_read!
    touch(:read_at)
  end

  private

  def set_message
    raise NotImplementedError, 'Subclasses must implement this method'
  end
end
