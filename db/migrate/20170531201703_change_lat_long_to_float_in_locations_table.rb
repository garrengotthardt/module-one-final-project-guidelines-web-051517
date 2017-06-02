class ChangeLatLongToFloatInLocationsTable < ActiveRecord::Migration[5.0]
  def change
    change_column :locations, :latitude, :real
    change_column :locations, :longitude, :real
  end
end
