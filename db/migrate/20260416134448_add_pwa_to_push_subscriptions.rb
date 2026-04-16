class AddPwaToPushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_column :push_subscriptions, :pwa, :boolean, default: false, null: false
  end
end
