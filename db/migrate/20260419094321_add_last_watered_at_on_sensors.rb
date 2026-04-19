class AddLastWateredAtOnSensors < ActiveRecord::Migration[8.1]
  def change
    add_column :sensors, :last_watered_at, :datetime, null: true
  end
end
