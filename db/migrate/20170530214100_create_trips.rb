class CreateTrips < ActiveRecord::Migration[5.0]

  def change
    create_table :trips do |t|
      t.integer :distance
      t.integer :estimated_cost
      t.references :user, index: true, foreign_key: true
      t.integer :start_location_id, index: true, foreign_key: true
      t.integer :end_location_id, index: true, foreign_key: true
    end
  end



end
