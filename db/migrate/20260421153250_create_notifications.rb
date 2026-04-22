class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.timestamps

      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :notifiable, polymorphic: true, null: true, type: :uuid

      t.string :type, null: false
      t.jsonb :data, default: {}, null: false

      t.datetime :read_at
    end

    add_index :notifications, %i[user_id read_at]
    add_index :notifications, %i[user_id created_at]
  end
end
