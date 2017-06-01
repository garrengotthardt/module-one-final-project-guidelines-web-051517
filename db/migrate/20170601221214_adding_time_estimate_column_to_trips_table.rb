class AddingTimeEstimateColumnToTripsTable < ActiveRecord::Migration[5.0]
  def change
    add_column :trips, :time_estimate, :string
  end
end
