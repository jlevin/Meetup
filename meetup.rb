# includes
require 'Geocoder'
require 'yelp'
require 'google_maps_service'

#configure Geocoder
Geocoder.configure(
:units => :m
)

# Start up yelp
client = Yelp::Client.new({ consumer_key: "x3G4T2iDTKoFp9LJK6pkIw",
                            consumer_secret: "RUCKnoXZYpGkotT4AbEdD5vjF5E",
                            token: "RXpAIyPszRc1KTEcVXMKBxIxaI1hDYA-",
                            token_secret: "MgIVGqsHEeRQEOWGiUk7LnHnTn4"
                          })

def midpoint(place_1, place_2)
  
  # Start up Google Maps API
  gmaps = GoogleMapsService::Client.new(key: 'AIzaSyD5aIWx1yAyM4ZNOMQ-LlOFYb0HGPzEa-0')
  
  route = gmaps.directions(
    place_1, place_2,
    mode: 'driving',
    alternatives: false)
  
  t_sum, d_sum, midpoint = 0, 0.0
  half_time = route[0][:legs][0][:duration][:value] / 2
  route[0][:legs][0][:steps].each do |x|
    t_sum += x[:duration][:value]
    if t_sum > half_time
#      return Geocoder::Calculations.geographic_center([[x[:start_location][:lat], x[:start_location][:lng]], [x[:end_location][:lat], x[:end_location][:lng]]])

      t_dist = x[:distance][:value]
      prev_n = x[:start_location]
      GoogleMapsService::Polyline.decode(x[:polyline][:points]).each do |n|
        distance = Geocoder::Calculations.distance_between([prev_n[:lat], prev_n[:lng]], [n[:lat], n[:lng]], {:units => :km}) / 1000
        if distance != nil
          d_sum += distance
        else
          puts "distance fucntion returned error with inputs:"
        end
        prev_n = n
        midpoint = n
      end
    end
    break if t_sum > half_time
  end
  return midpoint
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

# find midpoint & convert to coordinate format
# midpoint = Geocoder::Calculations.geographic_center([location_one, location_two])

# Check midpoint for driving equivalence, and refine with binary search
meetup = midpoint(midpoint(location_one, location_two), midpoint(location_two, location_one))

midpoint_coordinates = {latitude: meetup[:lat], longitude: meetup[:lng]}

# get recommendations
recs = client.search_by_coordinates(midpoint_coordinates, {term: search})

# display recommendations
puts "\nTop 5 Results:\n\n"
5.times do |i|
  puts recs.businesses[i].name
  puts recs.businesses[i].rating.to_s + "/5 Stars"
  recs.businesses[i].categories.each do |n|
    puts n[0]
  end
  
  # Calculate driving time for 1st person
  business = [recs.businesses[i].location.coordinate.latitude, recs.businesses[i].location.coordinate.longitude]
  gmaps = GoogleMapsService::Client.new(key: 'AIzaSyD5aIWx1yAyM4ZNOMQ-LlOFYb0HGPzEa-0')
  route = gmaps.directions(
      location_one, business,
      mode: 'driving',
      alternatives: false)
  
  puts route[0][:legs][0][:duration][:text].to_s + " for you."
  
  # Calculate driving time for 2nd person
  gmaps = GoogleMapsService::Client.new(key: 'AIzaSyD5aIWx1yAyM4ZNOMQ-LlOFYb0HGPzEa-0')
  route = gmaps.directions(
      location_two, business,
      mode: 'driving',
      alternatives: false)
  
  puts route[0][:legs][0][:duration][:text].to_s + " for the other person."
  
  puts "\n"
end