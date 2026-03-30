class CreatePlants < ActiveRecord::Migration[8.1]
  def change
    create_table :plants, id: :uuid do |t|
      t.timestamps

      t.string :name
      t.string :scientific_name
      t.string :trefle_id
      t.string :image_url
      t.float :min_temp
      t.float :max_temp
      t.integer :ideal_humidity
      t.jsonb :growth_data, default: {}
    end
  end
end
