require 'geokit'
require 'pry'
require 'soda'
require 'json'
require 'rest-client'


class CLI

  def welcome
    puts "--------------------------------------------".colorize(:color => :white, :background => :black)
    puts "     Welcome to NYC Yellow Cab booking!     ".colorize(:color => :white, :background => :black)
    puts "--------------------------------------------".colorize(:color => :white, :background => :black)
  end

  def app_description
    puts ""
    puts "By providing us your desired pickup and dropoff locaitons, we'll provide you with a fare estimate based on historic fare averages for the distance you're traveling. Given this estimate, if you'd like to book a ride, you'll be able to do so directly in the app.".colorize(:blue)
  end

  def get_user_input
    input = gets.chomp
    input
  end

  def collect_name_and_create_user
    puts ""
    puts "First off, please enter your first name:".colorize(:blue)
    first_name = get_user_input.downcase
    puts ""
    puts "Thanks! Now, please enter your last name:".colorize(:blue)
    last_name = get_user_input.downcase
    new_user = User.find_or_create_by(first_name: first_name, last_name: last_name)
    new_user
  end

  def get_origin_location
    puts ""
    puts "Please enter the address you're leaving from:".colorize(:blue)
    address = get_user_input
    if valid_address?(address) == true
      get_or_create_location_object(address)
    else
      puts ""
      puts "The address you entered is outside of our pick-up zone. We only serve the greater New York area including NY, NJ, & CT".colorize(:blue)
      get_origin_location
    end
  end

  def get_destination_location
    puts ""
    puts "Please enter your desired destination:".colorize(:blue)
    address = get_user_input
    if valid_address?(address) == true
      get_or_create_location_object(address)
    else
      puts ""
      puts "The address you entered is outside of our drop-off zone. We only serve the greater New York area including NY, NJ, & CT".colorize(:blue)
      get_destination_location
    end
  end

  def tell_user_trip_distance_and_estimate(distance, fare_estimate, time_estimate, origin_address, destination_address)
    d_district = get_district_from_geokit_object(destination_address)
    o_district = get_district_from_geokit_object(origin_address)
    # binding.pry
      if d_district != "Queens County" || d_district != "Kings County" || d_district != "New York County" || d_district != "Westchester County" || d_district != "Nassau County" || o_district != "Queens County" || o_district != "Kings County" || o_district != "New York County" || o_district != "Westchester County" || o_district != "Nassau County"
      puts ""
      puts "Your trip will be a total distance of #{distance} miles, will take aproximately #{time_estimate} given current traffic. Due to your destination being outside the New York County area (excluding Westchester and Nassau Counties) your fare will be a flat rate negotiated with the driver upon pick-up.".colorize(:blue)
      else
        if fare_estimate == NaN
          puts ""
          puts "Your trip will be a total distance of #{distance} miles, will take aproximately #{time_estimate} given current traffic.  Unfortunately, there is no historical data to support a fare estimate for a trip of this distance".colorize(:blue)
        else
          puts ""
          puts "Your trip will be a total distance of #{distance} miles, will take aproximately #{time_estimate} given current traffic, and has an estimated cost of $#{fare_estimate.round(2)}.".colorize(:blue)
        end
      end
  end

  def book_trip?(current_trip)
    puts ""
    puts "Do you want to book this trip? (Y/N)".colorize(:blue)
    answer = get_user_input
    if answer == "Y" || answer == "y"
      current_trip.update(trip_taken?: true)
      puts ""
      puts "Great, your car will be arrivng shortly!".colorize(:blue)
    elsif answer == "N" || answer == "n"
      puts ""
      puts "Ok, look forward to seeing you next time".colorize(:blue)
    else
      book_trip?(current_trip)
    end
  end

def valid_address?(address)
  state = get_state_from_geokit_object(address)
  if state == "NY" || state == "CT" || state == "NJ"
    true
  else
    false
  end
end


  def get_or_create_location_object(address)
    address_ll_array = get_address_latitude_longitude_array(address)
    full_address = get_full_address_from_geokit_object(address)
    location = Location.find_or_create_by(address: full_address, latitude: address_ll_array[0], longitude: address_ll_array[1])
    location
  end


  def get_geokit_object(address)
    geokit_object=Geokit::Geocoders::GoogleGeocoder.geocode address
    geokit_object
  end

  def get_address_latitude_longitude_array(address)
    geokit_object = get_geokit_object(address)
    lat_long_array = geokit_object.ll.split(",")
  end

  def get_full_address_from_geokit_object(address)
    geokit_object = get_geokit_object(address)
    geokit_object.full_address
  end

  def get_state_from_geokit_object(address)
    geokit_object = get_geokit_object(address)
    geokit_object.state_code
  end

  def get_district_from_geokit_object(address)
      geokit_object = get_geokit_object(address)
      geokit_object.district
  end


  def get_distance_between_start_and_end(origin_latitude, origin_longitude, destination_latitude, destination_longitude)
    url = RestClient.get(    "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=#{origin_latitude},#{origin_longitude}&destinations=#{destination_latitude},#{destination_longitude}&key=AIzaSyDov-Q98MaoRLqOVsifYPX1CjICrdAFlNA")
    trip_data_parsed = JSON.parse(url)
    trip_distance = trip_data_parsed["rows"][0]["elements"][0]["distance"]["text"]
    trip_distance.split(" ")[0].to_f
  end

    def get_time_estimate_between_start_and_end(origin_latitude, origin_longitude, destination_latitude, destination_longitude)
      url = RestClient.get(    "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=#{origin_latitude},#{origin_longitude}&destinations=#{destination_latitude},#{destination_longitude}&key=AIzaSyDov-Q98MaoRLqOVsifYPX1CjICrdAFlNA")
      trip_data_parsed = JSON.parse(url)
      time_estimate = trip_data_parsed["rows"][0]["elements"][0]["duration"]["text"]
      time_estimate
    end

  def get_all_fares_that_match_distance(distance)
    all_fares_2015 = RestClient.get('https://data.cityofnewyork.us/resource/2yzn-sicd.json')
    all_fares_2015_parsed = JSON.parse(all_fares_2015)
    all_fares_2015_parsed.find_all do |trip_hash|
      trip_hash["trip_distance"].to_f.round == distance
    end
  end

  def average_fare_cost_for_distance(distance)
    matched_trips_fares = []
    trips_distance_match = get_all_fares_that_match_distance(distance)
    trips_distance_match.each do |trip_hash|
      total_trip_cost_less_tip = (trip_hash["fare_amount"].to_f + trip_hash["imp_surcharge"].to_f + trip_hash["mta_tax"].to_f + trip_hash["tolls_amount"].to_f + trip_hash["extra"].to_f)
      matched_trips_fares << total_trip_cost_less_tip
    end
    average = matched_trips_fares.inject{ |sum, el| sum + el }.to_f / matched_trips_fares.size
    average
  end


end
