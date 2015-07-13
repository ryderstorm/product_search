require_relative '../libraries/main.rb'
require_relative '../libraries/digital_ocean.rb'
require_relative '../libraries/amazon.rb'
require_relative '../libraries/net_ssh.rb'

begin
	start = Time.now
	init_droplets
	# @droplet = create_droplet("medium")
	# ip = @droplet.ip_address
	# ip = @droplets.first.ip_address
	# command = "cd amazon_search/ && ls && git status && git checkout add_web_server && git status"
	# puts "\nRunning command:\n" + command.green + "\nvia SSH connection to:\n" + ip.green
	# result = ssh_command(ip, command)
	# puts "Command result was:\n" + result.yellow
	binding.pry


	puts "Finished testing"
rescue Exception => e
	puts e.message
	puts e.backtrace
	puts "Starting pry session after error..."
	binding.pry
ensure
	puts "Clearing resources"
	dots
	# Thread.list.each{|t| puts "#{Time.now} | Closing thread #{t}";t.join}
	no_dots
	puts "Resources cleared - exiting"
end