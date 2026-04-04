class CreateSensors < ActiveRecord::Migration[8.1]
  def change
    create_enum :sensor_location, %i[indoor outdoor]

    create_table :sensors, id: :uuid do |t|
      t.timestamps
      t.string :uid, null: false
      t.string :nickname
      t.string :secret_key, null: false

      t.enum :location, enum_type: :sensor_location, null: false, default: :indoor

      t.integer :moisture_threshold
      t.datetime :last_seen_at
      t.jsonb :current_data, default: {
        moisture_level: nil,
        temperature: nil,
        battery_level: nil
      }

      t.references :user, foreign_key: true, type: :uuid
      t.references :plant, foreign_key: true, type: :uuid
    end

    add_index :sensors, :uid, unique: true
    add_index :sensors, :secret_key, unique: true

    add_index :sensors, :current_data, using: :gin
  end
end
