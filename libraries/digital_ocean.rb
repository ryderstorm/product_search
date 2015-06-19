require 'dotenv'
Dotenv.load

require 'digitalocean'
Digitalocean.client_id  = @secrets[:do_client_id]
Digitalocean.api_key    = @secrets[:do_api_key]

regions = Digitalocean::Region.all
puts regions.inspect

droplets = Digitalocean::Droplet.all
puts droplets.inspect