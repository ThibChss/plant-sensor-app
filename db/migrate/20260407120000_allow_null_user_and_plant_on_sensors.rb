class AllowNullUserAndPlantOnSensors < ActiveRecord::Migration[8.1]
  def change
    change_column_null :sensors, :user_id, true
    change_column_null :sensors, :plant_id, true
  end
end
