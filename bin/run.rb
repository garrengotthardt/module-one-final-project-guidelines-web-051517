require_relative '../config/environment'
require 'pry'

cli_instance = CLI.new


cli_instance.welcome

cli_instance.app_description

user = cli_instance.collect_name_and_create_user

origin = cli_instance.get_origin_location

destination = cli_instance.get_destination_location

distance = cli_instance.get_distance_between_start_and_end(origin.latitude, origin.longitude, destination.latitude, destination.longitude)

time_estimate = cli_instance.get_time_estimate_between_start_and_end(origin.latitude, origin.longitude, destination.latitude, destination.longitude)


fare_estimate = cli_instance.average_fare_cost_for_distance(distance.round)

cli_instance.tell_user_trip_distance_and_estimate(distance, fare_estimate, time_estimate, origin.address, destination.address)

current_trip = Trip.create(user_id: user.id, origin_id: origin.id, destination_id: destination.id, distance: distance, estimated_cost: fare_estimate, trip_taken?: false, time_estimate: time_estimate)

cli_instance.book_trip?(current_trip)
