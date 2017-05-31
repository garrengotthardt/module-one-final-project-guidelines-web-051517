class CreateTrips < ActiveRecord::Migration[5.0]

  def change
    create_table :trips do |t|
      t.integer :distance
      t.integer :estimated_cost
      t.references :user, index: true, foreign_key: true
      t.integer :origin_id, index: true, foreign_key: true
      t.integer :destination_id, index: true, foreign_key: true
      t.boolean :trip_taken? :default => false
    end
  end



end
