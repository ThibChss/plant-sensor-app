class AddLastSeenAtOnUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_seen_at, :datetime, default: -> { 'CURRENT_TIMESTAMP' }

    add_index :users, :last_seen_at
  end
end
