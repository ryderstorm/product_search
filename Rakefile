require 'colorize'
$local_computer = false
unless File.exist?('secret/secret.txt')
	puts "Secret.txt doesn't exist and application cannot continue.".light_red
	exit
end

@root_folder = File.absolute_path(File.dirname(__FILE__))
require_relative 'libraries/main.rb'
begin
	task default: :notify
	# task local: %i(initialize start_logs amazon create_log create_spreadsheet pushbullet_files finish)
	desc "Run the search program locally"
	task local: %i(initialize start_logs amazon create_log create_spreadsheet finish)

	desc 'Notify user of available tasks'
	task :notify do
		puts "\n======================================================================================================".light_red
		puts "You are running Rake without specifying a task. Please rerun Rake and specify one of the following:"
		puts "local".ljust(10).yellow + " | run the search program on the local machine"
		puts "do_test".ljust(10).yellow + " | run the search program on a small size Digital Ocean machine with test data"
		puts "do_small".ljust(10).yellow + " | run the search program on a small size Digital Ocean machine with all data"
		puts "do_medium".ljust(10).yellow + " | run the search program on a medium size Digital Ocean machine with all data"
		puts "do_large".ljust(10).yellow + " | run the search program on a large size Digital Ocean machine with all data"
		puts "======================================================================================================".light_red
	end

	desc 'Initialze and report startup settings'
	task :initialize do
		puts "Initializing..."
		require_relative 'libraries/digital_ocean.rb'
		require_relative 'libraries/pushbullet.rb'
		require_relative 'libraries/amazon.rb'
		require_relative 'libraries/net_ssh.rb'
		Dir.mkdir('results') unless Dir.exist?('results')
		Dir.mkdir('temp') unless Dir.exist?('temp')
		init_variables
		dots
	end

	task :data_set_test do
		set_test_data(@root_folder + '/data/amazon_test.xlsx')
	end

	task :data_set_25 do
		set_test_data(@root_folder + '/data/amazon_25_products.xlsx')
	end

	task :data_set_250 do
		set_test_data(@root_folder + '/data/amazon_250_products.xlsx')
	end

	task :data_set_all do
		set_test_data(@root_folder + '/data/amazon_all_data.xlsx')
	end

	desc 'Create a small Digital Ocean droplet and run the search on it with test data'
	task :do_test do
		$local_computer = true
		Rake::Task["initialize"].invoke
		@remote_droplet = run_remote_search('small', 'test')
	end

	desc 'Create a small Digital Ocean droplet and run the search on it with all data'
	task :do_small do
		$local_computer = true
		Rake::Task["initialize"].invoke
		@remote_droplet = run_remote_search('small', 'all')
	end

	desc 'Create a medium Digital Ocean droplet and run the search on it with all data'
	task :do_medium do
		$local_computer = true
		Rake::Task["initialize"].invoke
		@remote_droplet = run_remote_search('medium', 'all')
	end

	desc 'Create a large Digital Ocean droplet and run the search on it with all data'
	task :do_large do
		$local_computer = true
		Rake::Task["initialize"].invoke
		@remote_droplet = run_remote_search('large', 'all')
	end

	desc 'Creates webserver for displaying log files'
	task :start_logs do
		if Socket.gethostname == "ryderstorm-amazon_search-1580844"
			ip = "$IP"
			port = "$PORT"
			remote_link = "https://amazon-search-ryderstorm.c9.io/?_c9_id=livepreview20&_c9_host=https://ide.c9.io"
		else
			ip = "0.0.0.0"
			port = "8100"
			remote_link = "http://#{@remote_ip}:#{port}"
		end
		weblog = "temp/webserver_log_#{@run_stamp}.txt"
		puts "\n" + log("Starting log server...")
		@webserver = Thread.new{ system("ruby bin/log_viewer.rb #{@run_stamp} -o #{ip} -p #{port} >> #{File.absolute_path(weblog)} 2>&1 &")}
		puts log "Log server running at: #{remote_link.blue}"
		puts log "Log server logs at: #{File.absolute_path(weblog).blue}"
		pushbullet_link_to_all("Log viewer running", remote_link, "")
	end

	desc 'Search amazon for the specified skus'
	task :amazon do
		begin
			puts "\n" + log("Starting Amazon search...")
			@amazon_products = []
			@data_groups = read_amazon_data(@group_size)
			File.write(@product_log, "0|#{@amazon_product_count}")
			log "Number of data groups: #{@data_groups.count}\n"
			if @headless
				log "Running headless\n"
				headless = Headless.new
				headless.start
			end
			@threads = []
			@completed = []
			@browsers = Array.new(@data_groups.count)

			@data_groups.each_with_index do |data, i|
				batch_number = i.to_s.rjust(@data_groups.count.to_s.length, '0')
				loop do
					# ready_to_go = free_core
					# puts "\n#{local_time} | Freecore = #{ready_to_go ? ready_to_go.to_s.green : ready_to_go.to_s.light_red} | #{@threads.count.to_s.light_blue} / #{@cores.to_s.green}"
					# ap @threads
					# if ready_to_go
					if free_core
						break
					else
						@threads.delete_if { |t| !t.alive? }
						sleep 2
					end
				end
				sleep 2
				break if @error
				new = Thread.new do
					begin
						log "Amazon search [#{batch_number}] of [#{@data_groups.count-1}] starting..."
						log "Creating browser instance #{batch_number}"
						client = Selenium::WebDriver::Remote::Http::Default.new
						client.timeout = 180 # seconds – default is 60
						@browsers[i] = Watir::Browser.new :firefox, :http_client => client
						search_result = amazon_search(@browsers[i], data, batch_number)
					rescue => e
						puts report_error("Encountered error during browser creation in Rake:amazon", e)
					ensure
						log "Closing browser instance [#{i}]..."
						@browsers[i].close rescue nil
						search_status = "Amazon search [#{batch_number}] with browser(#{i}) ended with status: #{search_result}"
						@completed.push search_status
						log search_status
					end
				end
				@threads.push new
				# @threads.delete_if { |t| !t.alive? }
			end
			puts "\n" + log("All browser instances have been created".light_blue)
			loop do
				if @completed.count == @data_groups.count
					puts "\n" + log("All searches complete!".green)
					break
				end
				if Time.parse(local_time.uncolorize) - @start_time > 3000
					puts log("Search has been running for over 50 minutes and will now be closed.".light_red)
					break
				end
				sleep 1
			end
		rescue Interrupt
			puts log "User pressed Ctrl+C".yellow
			# binding.pry
		rescue => e
			puts report_error("Encountered error during Rake:amazon", e)
			# binding.pry
		ensure
			@threads.each {|t| t.join(1)}
			@browsers.each { |b| b.close rescue nil}
			headless.destroy if @headless
		end
	end

	desc 'Creates the finalized spreadsheet from all the other spreadsheets'
	task :create_spreadsheet do
		puts "#{local_time} | Opening workbook..."
		workbook = create_master_spreadsheet
		open_file(workbook)
	end

	desc 'Creates a master log file from all of the other logs'
	task :create_log do
		puts "#{local_time} | Creating master logs"
		@all_runs_log = create_master_log
		log "Logfile generated at this location:\n#{@all_runs_log}"
	end

	desc 'Pusbullet file results'
	task :pushbullet_files do
		puts "#{local_time} | Sending files via pushbullet"
		begin
			Dir.glob('results/*').each do |file|
				if File.basename(file).include?(@run_stamp)
					pushbullet_file_to_all(File.basename(file), file, "", @chrome)
				end
			end
		rescue Exception => e
			# puts e.message
			# puts e.backtrace
			puts log "Encountered error during pushbullet, probably has to do with stupid windows pushbullet issues"
		end
	end

	desc 'Report total time'
	task :finish do
		puts "\n#{local_time} | Finishing up"
		begin
			title = "Product scraping complete on #{@computer}"
			message = @errors.empty? || @errors.nil? ? "Process completed with no errors!".green : "Process completed but contained errors!".light_red
			message << "\nTotal processing time: #{seconds_to_string(Time.parse(local_time.uncolorize) - @start_time)}"
			pushbullet_note_to_all(title, message)
			puts log title
			puts log message
			# puts "Opening log file: #{@master_log}"
			# sleep 3
			# open_file(@master_log)
			no_dots
		rescue => e
			puts report_error(e, "Error encountered during :finish task")
			# binding.pry
			# puts log "Encountered error during report total time, probably has to do with stupid windows pushbullet issues"
		end
	end

	at_exit do
		puts "#{local_time} | Performing at_exit stuff"
		if $local_computer == true
			unless Digitalocean::Droplet.all.droplets.count == 0
				no_dots
				get_droplets
				puts "============================================".yellow
				puts "Your session used remote droplet [#{@remote_droplet.name.light_blue}]" unless @remote_droplet.nil?
				puts "Do you want to destroy this droplet?".cyan
				puts "Enter " + "Y".green + " for yes, " + "P".light_blue + " to pause and start a pry session, " + "All".light_red + " to delete all droplets, and anything else for no"
				puts "============================================".yellow
				user_choice = STDIN.gets.chomp.downcase
				case user_choice
				when  'y'
					destroy_droplet(@remote_droplet)
				when 'p'
					puts "Starting pry session"
					binding.pry
					puts "Pry session ended - closing up shop"
				when 'all'
					puts "Destroying all #{Digitalocean::Droplet.all.droplets.count.to_s.light_red} droplets"
					destroy_all_droplets
				else
					puts "The following droplets will remain active:"
					get_droplets
				end
			end
		end
		log_errors unless @errors.nil? || @errors.empty?
		# if @computer == 'ryderstorm-amazon_search-1580844'
			# puts "Pausing for log investigation".light_red
			# binding.pry
			# `curl "https://amazon-search-ryderstorm.c9.io/terminate?_c9_id=livepreview20&_c9_host=https://ide.c9.io"`
		# end
	end
rescue => e
	puts report_error(e)
end
