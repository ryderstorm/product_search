require_relative '../libraries/main.rb'
require_relative '../libraries/digital_ocean.rb'
require_relative '../libraries/amazon.rb'
require_relative '../libraries/net_ssh.rb'

begin
	puts File.expand_path(File.dirname(__FILE__))[0..-5]
	start = Time.now
	wtf
	# init_droplets
	# new_droplet = create_droplet('small')
	# sleep 3
	# puts ssh_output = ssh_rake(new_droplet.ip_address, '25')
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
	puts report_error(e, "Error encountered during test.rb")
	binding.pry
# ensure
# 	puts "============================================".yellow
# 	puts "Do you want to destroy all droplets?".yellow
# 	puts "Y".green + " for yes, anything else for no"
# 	puts "============================================".yellow
# 	if gets.chomp == 'y'
# 	destroy_all_droplets
# 	# Thread.list.each{|t| puts "#{Time.now} | Closing thread #{t}";t.join}
# 	no_dots
# 	puts "Resources cleared - exiting"
end