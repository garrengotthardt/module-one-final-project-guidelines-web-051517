require 'geokit'
require 'pry'
require 'soda'
require 'json'
require 'rest-client'


class CLI

  def welcome
    puts "--------------------------------------------".colorize(:color => :white, :background => :blue)
    puts "     Welcome to NYC Yellow Cab booking!     ".colorize(:color => :white, :background => :blue)
    puts "--------------------------------------------".colorize(:color => :white, :background => :blue)
  end

  def app_description
    puts ""
    puts "By providing us your desired pickup and dropoff locations, we'll provide you with:".colorize(:blue)
    puts ""
    puts "— the distance you'll be travelling".colorize(:blue)
    puts "— the estimated duration of your trip based on current traffic".colorize(:blue)
    puts "— the estimated cost of your trip based on the average cost recent trips of a similar distance".colorize(:blue)
    puts ""
    puts "Given this estimate, if you'd like to book a ride, you'll be able to do so directly in the app.".colorize(:blue)
  end

  def get_user_input
    gets.chomp
  end

  def collect_name_and_create_user
    puts ""
    puts "First off, please enter your first name:".colorize(:blue)
    first_name = get_user_input.downcase
    puts ""
    puts "Thanks! Now, please enter your last name:".colorize(:blue)
    last_name = get_user_input.downcase
    User.find_or_create_by(first_name: first_name, last_name: last_name)
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
    # d_district = get_district_from_geokit_object(destination_address)
    # o_district = get_district_from_geokit_object(origin_address)
    # binding.pry
      if check_if_address_county_is_valid(origin_address) == false || check_if_address_county_is_valid(destination_address) == false
        binding.pry
          puts ""
          puts "Your trip will be a total distance of #{distance} miles, will take aproximately #{time_estimate} given current traffic. Because either your origin or destination is outside the New York County area, your fare will be a flat rate negotiated with the driver upon pick-up.".colorize(:blue)
      else
        if fare_estimate.nan?
          # binding.pry
          puts ""
          puts "Your trip will be a total distance of #{distance} miles, will take aproximately #{time_estimate} given current traffic.  Unfortunately, there is no historical data to support a fare estimate for a trip of this distance.".colorize(:blue)
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
      ascii_taxi
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
    Location.find_or_create_by(address: get_full_address_from_geokit_object(address), latitude: get_address_latitude_longitude_array(address)[0], longitude: get_address_latitude_longitude_array(address)[1])
  end


  def get_geokit_object(address)
    Geokit::Geocoders::GoogleGeocoder.geocode address
  end

  def get_address_latitude_longitude_array(address)
    get_geokit_object(address).ll.split(",")
  end

  def get_full_address_from_geokit_object(address)
    get_geokit_object(address).full_address
  end

  def get_state_from_geokit_object(address)
    get_geokit_object(address).state_code
  end

  def get_district_from_geokit_object(address)
    get_geokit_object(address).district
  end

  def check_if_address_county_is_valid(address)
    district = get_district_from_geokit_object(address)
    ["Queens County", "Kings County", "New York County", "Richmond County", "Bronx County", "Westchester County", "Nassau County"].include?(district)
  end

  def get_distance_between_start_and_end(origin_latitude, origin_longitude, destination_latitude, destination_longitude)
    JSON.parse(RestClient.get(    "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=#{origin_latitude},#{origin_longitude}&destinations=#{destination_latitude},#{destination_longitude}&key=AIzaSyDov-Q98MaoRLqOVsifYPX1CjICrdAFlNA"))["rows"][0]["elements"][0]["distance"]["text"].split(" ")[0].to_f
  end

  def get_time_estimate_between_start_and_end(origin_latitude, origin_longitude, destination_latitude, destination_longitude)
    JSON.parse(RestClient.get(    "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=#{origin_latitude},#{origin_longitude}&destinations=#{destination_latitude},#{destination_longitude}&key=AIzaSyDov-Q98MaoRLqOVsifYPX1CjICrdAFlNA"))["rows"][0]["elements"][0]["duration"]["text"]
  end

  def get_all_fares_that_match_distance(distance)
   JSON.parse(RestClient.get('https://data.cityofnewyork.us/resource/2yzn-sicd.json')).select do |trip_hash|
      trip_hash["trip_distance"].to_f.round == distance
    end
  end

  def average_fare_cost_for_distance(distance)
    matched_trips_fares = get_all_fares_that_match_distance(distance).map do |trip_hash|
      (trip_hash["fare_amount"].to_f + trip_hash["imp_surcharge"].to_f + trip_hash["mta_tax"].to_f + trip_hash["tolls_amount"].to_f + trip_hash["extra"].to_f)
    end
    matched_trips_fares.inject{ |sum, el| sum + el }.to_f / matched_trips_fares.size
  end



  def ascii_taxi
    puts '                   [\                     '.colorize(:yellow)
    puts '              .----" `-----.              '.colorize(:yellow)
    puts '             //^^^^;;^^^^^^`\             '.colorize(:yellow)
    puts '     _______//_____||_____()_\________    '.colorize(:yellow)
    puts '    /NYC826 :      :                  `\  '.colorize(:yellow)
    puts '   |>   ____;      ; NYC TAXI  ____   _<) '.colorize(:yellow)
    puts '  {____/    \_________________/    \____} '.colorize(:yellow)
    puts '       \ "" /                 \ "" /      '.colorize(:yellow)
    puts '        "--"                   "--"       '.colorize(:yellow)
  end


end
