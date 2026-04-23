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
module Notifications
  class MoistureLow < Notification
    private

    def set_message
      return unless message.blank?

      self.message = I18n.t('notifications.moisture_low.message', plant_name: notifiable.plant.name)
    end
  end
end
