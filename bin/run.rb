require_relative 'config/environment'

cli_instance = CLI.new


cli_instance.welcome

cli_instance.app_description

user = cli_instance.collect_name_and_create_user

origin = cli_instance.get_origin_location

destination = cli_instance.get_destination_location

distance = cli_instance.get_distance_between_start_and_end(origin.address, destination.address)

estimate = cli_instance.average_fare_cost_for_distance(distance.round)

tell_user_trip_distance_and_estimate(distance, estimate)

current_trip = Trip.create(user_id: user.id, origin_id: origin.id, destination_id: destination.id, distance: distance, estimated_cost: estimate)

cli_instance.book_trip?(current_trip)
