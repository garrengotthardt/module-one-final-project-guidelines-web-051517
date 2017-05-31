require "pry"


class Trip < ActiveRecord::Base
  belongs_to :user
  belongs_to :start_location, :class_name => "Location", :foreign_key => :start_location_id
  belongs_to :end_location, :class_name => "Location", :foreign_key => :end_location_id



  def fair_estimate_calculator(distance)
    all_fares_2015 = RestClient.get('https://data.cityofnewyork.us/resource/2yzn-sicd.json')
    trips_distance_match = all_fares_2015.collect do |trip_hash|
      trip_hash[trip_distance:].round == distance
    end
    fares_for_average = []
    trips_distance_match.each do |trip_hash|
      

  end

end
