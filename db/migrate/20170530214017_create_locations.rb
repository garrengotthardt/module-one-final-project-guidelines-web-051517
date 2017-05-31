class CreateLocations < ActiveRecord::Migration[5.0]

  def change
    create_table :locations do |t|
      t.string :address
      t.integer :latitude
      t.integer :longitude
    end
  end


end
