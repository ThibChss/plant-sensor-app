# == Schema Information
#
# Table name: push_subscriptions
#
#  id         :uuid             not null, primary key
#  auth_key   :string
#  endpoint   :string
#  p256dh_key :string
#  pwa        :boolean          default(FALSE), not null
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_push_subscriptions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class PushSubscription < ApplicationRecord
  belongs_to :user

  def deliver(message:)
    Notifications::WebPushJob.perform_later(message:, subscription: self)
  end
end
