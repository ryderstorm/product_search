require 'awesome_print'
require 'pry'
require 'pry-byebug'
require 'colorize'
# require_relative 'main.rb'

require 'dotenv'
Dotenv.load

require 'digitalocean'

begin

	def init_droplets
	  spacer = '============================================================'
		init_variables if @secrets.nil?
		Digitalocean.client_id  = @secrets[:do_client_id]
		Digitalocean.api_key    = @secrets[:do_api_key]
		number_of_droplets = Digitalocean::Droplet.all.droplets.count
    if number_of_droplets == 0
			puts "\n#{spacer}\nThere are no droplets on your account.\n#{spacer}\n".yellow
		else
		  puts spacer.light_blue
		  get_droplets
			puts "\nDroplets can be accessed via ".light_blue + "@droplets".red.on_yellow
    end
		puts "\nAvailable methods are:".light_blue
		puts "get_droplets".yellow
		puts "destroy_all_droplets".yellow
		puts "droplet_status(droplet)".yellow
		puts "create_droplet(size)".yellow
		puts spacer.light_blue
	end

	def droplet_status(droplet)
		"#{droplet.name.to_s.ljust(40)} | #{droplet.status.to_s.center(8).red} | $#{hourly_cost(droplet.size_id)} | #{droplet.id.to_s.ljust(8)} | #{droplet.ip_address.to_s.ljust(16)}"
	end

	def hourly_cost(size_id)
		Digitalocean::Size.all.sizes.each { |s| return s.cost_per_hour.round(3) if s.id == size_id }
		"no matching hourly cost found for size_id: #{size_id}"
	end

	def create_droplet(size = 'small')
		case size
		when 'small'
		  size_id = 63
		when 'medium'
		  size_id = 65
		when 'large'
		  size_id = 69
		end
		name = "Crue-marketing-search-#{size}-#{Time.now.strftime("%Y%m%d-%H%M%S")}"
		puts "Creating droplet [" + name.yellow + "]"
		image_id = 12704267
		region_id = 8
		ssh_key_id = 971823
		ssh_key_ids = []
		Digitalocean::SshKey.all.ssh_keys.each { |k| ssh_key_ids.push k.id }
		create_droplet = Digitalocean::Droplet.create({name: name, size_id: size_id, image_id: image_id, region_id: region_id, ssh_key_ids: ssh_key_id})
		id = create_droplet.droplet.id

		puts "Waiting for droplet to become active"
		counter = 0
		loop do
			if counter > 50 and counter % 2 == 0
				break if Digitalocean::Droplet.find(id).droplet.status == 'active'
			end
			if counter == 300
				puts "Droplet creation taking longer than 5 minutes, please investigate".red
				# binding.pry
				return create_droplet
			end
			sleep 0.5
			counter += 0.5
			print "."
			puts "\nWaited #{counter} seconds so far. Droplet status is #{Digitalocean::Droplet.find(id).droplet.status.blue}\n" if counter % 10 == 0
		end
		puts "\nSuccess!".green
		puts "Droplet created in #{counter} seconds.\nStatus is now #{Digitalocean::Droplet.find(id).droplet.status.yellow}"
		get_droplets
		return Digitalocean::Droplet.find(id).droplet
	end

	def get_droplets
	  @droplets = []
    if Digitalocean::Droplet.all.droplets.count == 0
  	  puts "\nNo droplets found!".yellow
  	  return
    end
    puts "There are ".light_blue + Digitalocean::Droplet.all.droplets.count.to_s.yellow + " droplets on your account".light_blue
		Digitalocean::Droplet.all.droplets.each do |d|
			puts droplet_status(d).green
			@droplets.push d
		end
	end

	def destroy_droplet(droplet)
	  puts "Destroying droplet #{droplet.name}"
	  dots
		Digitalocean::Droplet.destroy(droplet.id)
		counter = 0
		loop do
		  if Digitalocean::Droplet.find(droplet.id).droplet.status == 'archive'
		    puts "Droplet destroyed successfully. Status is now [#{Digitalocean::Droplet.find(droplet.id).droplet.status}]"
		    no_dots
		    return
		  end
		  sleep 1
		  counter += 1
		  if counter > 10
		    no_dots
		    puts "It is taking longer than 10 seconds to destroy droplet #{droplet.name}, please investigate!"
		    return
		  end
		end
	end

	def destroy_all_droplets
	  puts "No droplets to destroy!" if Digitalocean::Droplet.all.droplets.count == 0
		Digitalocean::Droplet.all.droplets.each { |d| destroy_droplet(d) }
		10.times do
		  puts "."
  		if Digitalocean::Droplet.all.droplets.count == 0
  		  puts "All droplets succesffully destroyed."
  		  return
  		else
  		  sleep 1
  		end
		end
		get_droplets
		puts "Not all droplets were deleted, please investigate! Droplet count: #{Digitalocean::Droplet.all.droplets.count}"
	end

rescue Interrupt
	puts "Interrupted by user, starting pry session...".yellow
	binding.pry
rescue => e
	puts e.class
	puts e.message
	puts e.backtrace
	puts "Encountered error shown above, starting pry session".red
	binding.pry
ensure
	puts "all done"
end
