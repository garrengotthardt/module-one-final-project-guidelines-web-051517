require "pry"

class Location < ActiveRecord::Base
  has_many :trips
  has_many :users, through: :trips

# def initialize(address, latitude, longitude)
#   @address = address
#   @latitude = latitude
#   @longitude = longitude
# end

end
