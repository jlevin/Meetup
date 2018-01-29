# includes
require 'yelp'
require 'google_maps_service'

# Setup global parameters for Yelp
Yelp.client.configure do |config|
  config.consumer_key = "Add your consumer key"
  config.consumer_secret = "Add your consumer secret"
  config.token = "Add your token"
  config.token_secret = "Add your token secret"
end

# Setup global parameters for Google_Maps_Service
GoogleMapsService.configure do |config|
  config.key = 'Add your key'
  config.retry_timeout = 20
  config.queries_per_second = 10
end