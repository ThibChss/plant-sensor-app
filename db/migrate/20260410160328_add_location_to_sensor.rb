class AddLocationToSensor < ActiveRecord::Migration[8.1]
  def up
    rename_enum :sensor_location, :sensor_environment
    rename_column :sensors, :location, :environment

    add_column :sensors, :location, :string
  end

  def down
    remove_column :sensors, :location

    rename_enum :sensor_environment, :sensor_location
    rename_column :sensors, :environment, :location
  end
end
