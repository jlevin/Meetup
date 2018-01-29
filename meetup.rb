# includes
require 'Geocoder'
require_relative 'meetup.config'

# configure Geocoder
Geocoder.configure(
:units => :m
)

def midpoint(place_1, place_2)
  # Initialize Google Maps API
  gmaps = GoogleMapsService::Client.new

  route = gmaps.directions(
    place_1, place_2,
    mode: 'driving',
    alternatives: false)

  # initialize global variables, halfway is half of the total trip distance
  d_sum, midpoint = 0, 0
  halfway = route[0][:legs][0][:distance][:value] / 2

  # increments through the steps in the directions until "halfway" is exceeded
  route[0][:legs][0][:steps].each do |x|
    d_sum += x[:distance][:value]
    if d_sum > halfway

      # decrease distance by the most recent step
      d_sum -= x[:distance][:value]

      # Increment through polyline coordinates until halfway distance is reached
      prev_n = x[:start_location]
      GoogleMapsService::Polyline.decode(x[:polyline][:points]).each do |n|
        distance = Geocoder::Calculations.distance_between([prev_n[:lat], prev_n[:lng]], [n[:lat], n[:lng]], {:units => :km}) * 1000
        if d_sum < halfway

          # increase distance by polyline segment length
          d_sum += distance
          prev_n = n

        else
          midpoint = prev_n
          return midpoint
        end
      end
    end
  end
end

# Get first location
puts "Where are you coming from?"
location_one = Geocoder.coordinates(gets.chomp)

# validate input
while location_one == nil
  puts "Location not valid. Try again:"
  location_one = Geocoder.coordinates(gets.chomp)
end

# Get second location
puts "Where is the other person coming from?"
location_two = Geocoder.coordinates(gets.chomp)

# Get type of establishment
puts "Where do you want to meet? (e.g. \"bar\", \"cafe\")"
search = gets.chomp

# validate input
while location_two == nil
  puts "Location not valid.  Try again:"
  location_two = Geocoder.coordinates(gets.chomp)
end

# Find the midpoint between the midpoints for forward and reverse directions, convert to Yelp coordinates format
meetup = midpoint(midpoint(location_one, location_two), midpoint(location_two, location_one))
midpoint_coordinates = {latitude: meetup[:lat], longitude: meetup[:lng]}

# get recommendations
recs = Yelp.client.search_by_coordinates(midpoint_coordinates, {term: search})

# display recommendations
puts "\nTop 5 Results:\n\n"
5.times do |i|
  puts recs.businesses[i].name
  puts recs.businesses[i].rating.to_s + "/5 Stars"
  recs.businesses[i].categories.each do |n|
    puts n[0]
  end

  # Calculate driving distance for 1st person
  business = [recs.businesses[i].location.coordinate.latitude, recs.businesses[i].location.coordinate.longitude]
  gmaps = GoogleMapsService::Client.new
  route = gmaps.directions(
      location_one, business,
      mode: 'driving',
      alternatives: false)

  # Dispays driving distance for user
  puts route[0][:legs][0][:distance][:text].to_s + " for you."

  # Calculate driving distance for 2nd person
  gmaps = GoogleMapsService::Client.new
  route = gmaps.directions(
      location_two, business,
      mode: 'driving',
      alternatives: false)

  # Dispays driving distance for other person
  puts route[0][:legs][0][:distance][:text].to_s + " for the other person."

  puts "\n"
end