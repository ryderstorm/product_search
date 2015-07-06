require 'pry'
require 'pry-byebug'
require 'colorize'
require_relative 'main.rb'

require 'dotenv'
Dotenv.load

require 'digitalocean'

begin

	def init_droplets
		init_variables if @secrets.nil?
		Digitalocean.client_id  = @secrets[:do_client_id]
		Digitalocean.api_key    = @secrets[:do_api_key]
		# Digitalocean.client_id  = '07afc59e662610137c264edfa354dbbb'
		# Digitalocean.api_key    = 'b020149a87c523551cca5dec543984eb'
		number_of_droplets = Digitalocean::Droplet.all.droplets.count
		if number_of_droplets == 0 
			puts "\n========================================\nThere are no droplets on your account.\n========================================\n".colorize(:green)
		else
			puts "\n========================================\nThe following droplets exist on your account:\n========================================\n".colorize(:light_blue)
			get_droplets
			puts "\nThey have been stored in #{"@droplets".colorize(:light_blue)}\nAvailable options are:\n#{"get_droplets".colorize(:yellow)}\n#{"destroy_all_droplets".colorize(:yellow)}\n#{"droplet_status(droplet)".colorize(:yellow)}\n#{"create_medium_droplet".colorize(:yellow)}"
		end
	end

	def droplet_status(droplet)
		"#{droplet.name.to_s.ljust(40)} | #{droplet.status.to_s.center(8).colorize(:red)} | $#{hourly_cost(droplet.size_id)} | #{droplet.id.to_s.ljust(8)} | #{droplet.ip_address.to_s.ljust(16)}"
	end

	def hourly_cost(size_id)
		Digitalocean::Size.all.sizes.each { |s| return s.cost_per_hour.round(3) if s.id == size_id }
		"no matching hourly cost found for size_id: #{size_id}"
	end

	def create_medium_droplet
		name = "Crue-marketing-search-#{Time.now.strftime("%Y%m%d-%H%M%S")}"
		image_id = 12557649
		size_id = 65
		region_id = 8
		ssh_key_id = 918849
		ssh_key_ids = []
		Digitalocean::SshKey.all.ssh_keys.each { |k| ssh_key_ids.push k.id }
		create_droplet = Digitalocean::Droplet.create({name: name, size_id: size_id, image_id: image_id, region_id: region_id, ssh_key_ids: ssh_key_ids})
		new_droplet = Digitalocean::Droplet.find(create_droplet.droplet.id)
		print "Waiting for droplet to become active"
		counter = 0
		loop do

			if counter > 80
				break if new_droplet.droplet.status == 'active'
			end
			if counter == 120
				puts "Droplet creation taking longer than 75 seconds, please investigate".colorize(:red)
				binding.pry
				return create_droplet
			end
			sleep 1
			print '.'
			counter += 1
			puts "\nWaited #{counter} seconds so far. Droplet status is \n#{create_droplet}\n" if counter % 10 == 0
		end
		puts "Droplet created in #{counter} seconds.\nStatus is now #{new_droplet.droplet.status.colorize(:yellow)}"
		return new_droplet
	end

	def get_droplets
		@droplets = []
		Digitalocean::Droplet.all.droplets.each do |d|
			puts droplet_status(d).colorize(:blue)
			@droplets.push d
		end
	end

	def destroy_droplet(droplet)
		status = Digitalocean::Droplet.destroy(droplet.id)
		# do something here to monitor status
	end

	def destroy_all_droplets
		Digitalocean::Droplet.all.droplets.each { |d| destroy_droplet(d) }		
		if Digitalocean::Droplet.all.droplets.count != 0
			puts "Not all droplets were deleted, please investigate!"
		end
	end

rescue Interrupt
	puts "Interrupted by user, starting pry session...".colorize(:yellow)
	binding.pry
rescue => e
	puts e.class
	puts e.message
	puts e.backtrace
	puts "Encountered error shown above, starting pry session".colorize(:red)
	binding.pry
ensure
	puts "all done"
end
