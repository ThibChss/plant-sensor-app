class CreatePushSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :push_subscriptions, id: :uuid do |t|
      t.timestamps

      t.references :user, foreign_key: true, type: :uuid, null: false, index: true

      t.string :endpoint
      t.string :p256dh_key
      t.string :auth_key

      t.string :user_agent
    end
  end
end
