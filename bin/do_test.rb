require_relative '../libraries/main.rb'
require_relative '../libraries/digital_ocean.rb'
require_relative '../libraries/amazon.rb'
require_relative '../libraries/net_ssh.rb'
require 'usagewatch'

begin
	puts File.expand_path(File.dirname(__FILE__))[0..-5]
	start = Time.now
	init_droplets
	# if @droplets.nil? or @droplets.empty?
	# 	new_droplet = create_droplet('medium')
	# 	ip = new_droplet.ip_address
	# else
	# 	ip = @droplets.first.ip_address
	# end
	# puts ssh_output = ssh_rake(ip, 'all')
	# @droplet = create_droplet("medium")
	# ip = @droplet.ip_address
	# ip = @droplets.first.ip_address
	# command = "cd amazon_search/ && ls && git status && git checkout add_web_server && git status"
	# puts "\nRunning command:\n" + command.green + "\nvia SSH connection to:\n" + ip.green
	# result = ssh_command(ip, command)
	# puts "Command result was:\n" + result.yellow
	binding.pry


	puts "Finished testing"
rescue => e
	puts "Starting pry session after error..."
	puts report_error(e, "Error encountered during do_test.rb")
	binding.pry
ensure
	unless Digitalocean::Droplet.all.droplets.count == 0
		puts "============================================".yellow
		puts "Do you want to destroy all droplets?".yellow
		puts "Y".green + " for yes, anything else for no"
		puts "============================================".yellow
		if STDIN.gets.chomp == 'y'
			destroy_all_droplets
			puts "Resources cleared - exiting"
		else
			puts "The following droplets will remain active:"
			get_droplets
		end
	end
end