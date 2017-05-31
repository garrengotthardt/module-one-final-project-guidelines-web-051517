require "pry"

class User < ActiveRecord::Base
  has_many :trips
  has_many :destinations, through: :trips

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end




end
# require 'geokit'
# def get_start_location_latitude_longitude(start_address)
#   start=Geokit::Geocoders::GoogleGeocoder.geocode start_address
#   start
# end
#
# def get_end_location_latitude_longitude(end_address)
#   destination=Geokit::Geocoders::GoogleGeocoder.geocode end_address
#   destination
# end
#
# def get_distance_between_start_and_end(start_address, end_address)
#   get_start_location_latitude_longitude(start_address).distance_to(get_end_location_latitude_longitude(end_address)).round
# end
