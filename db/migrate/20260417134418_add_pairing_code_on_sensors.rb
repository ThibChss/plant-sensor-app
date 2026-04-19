class AddPairingCodeOnSensors < ActiveRecord::Migration[8.1]
  def change
    add_column :sensors, :pairing_code, :string, null: true
  end
end
