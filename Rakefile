require 'colorize'
unless File.exist?('secret/secret.txt')
	puts "Secret.txt doesn't exist and application cannot continue.".red.on_yellow
	exit
end

@root_folder = File.absolute_path(File.dirname(__FILE__))

task default: :notify
task local: %i(initialize start_logs amazon create_log create_spreadsheet pushbullet_files finish)

desc 'Notify user of available tasks'
task :notify do
	puts "\n======================================================================================================".red
	puts "You are running Rake without specifying a task. Please rerun Rake and specify one of the following:"
	puts "local".ljust(10).yellow + " | run the search program on the local machine"
	puts "do_medium".ljust(10).yellow + " | run the search program on a medium size Digital Ocean machine"
	puts "do_large".ljust(10).yellow + " | run the search program on a large size Digital Ocean machine"
	puts "======================================================================================================".red
end

desc 'Initialze and report startup settings'
task :initialize do
	puts "Initializing..."
	require_relative 'libraries/main.rb'
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

task :data_set_all do
	set_test_data(@root_folder + '/data/amazon_all_data.xlsx')
end

desc 'Create a small Digital Ocean droplet and run the search on it'
task :do_medium do
	run_remote_search('small')
end

desc 'Create a medium Digital Ocean droplet and run the search on it'
task :do_medium do
	run_remote_search('medium')
end

desc 'Create a large Digital Ocean droplet and run the search on it'
task :do_large do
	run_remote_search('large')
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
	puts "#{Time.now.to_s.yellow} | Starting log server at #{remote_link}"
	Thread.new{ system("ruby bin/log_viewer.rb #{@run_stamp} -o #{ip} -p #{port}")}
	pushbullet_link_to_all("Log viewer running", remote_link, "")
end

desc 'Search amazon for the specified skus'
task :amazon do
	begin
		puts log @main_log, "#{Time.now.to_s.yellow} | Starting Amazon search..."
		@amazon_products = []
		@data_groups = read_amazon_data(@group_size)
		File.write(@product_log, "0|#{@amazon_product_count}")
		log @main_log, "#{Time.now} | Number of data groups: #{@data_groups.count}\n"
		if @headless
			log @main_log, "#{Time.now} | Running headless\n"
			headless = Headless.new
			headless.start
		end
		@threads = []
		@completed = []
		@browsers = Array.new(@data_groups.count)

		@data_groups.each_with_index do |data, i|
			batch_number = i.to_s.rjust(@data_groups.count.to_s.length, '0')
			sleep 1 while !free_core
			sleep 2
			break if @error
			new = Thread.new do
				begin
					log @main_log, "#{Time.now} | Amazon search [#{batch_number}] of [#{@data_groups.count-1}] starting..."
					log @main_log, "#{Time.now} | Creating browser instance #{batch_number}"
					client = Selenium::WebDriver::Remote::Http::Default.new
					client.timeout = 180 # seconds – default is 60
					@browsers[i] = Watir::Browser.new :firefox, :http_client => client
					amazon_search(@browsers[i], data, batch_number)
				rescue => e
					puts report_error("Encountered error during browser creation in Rake:amazon", e)
				ensure
					log @main_log, "#{Time.now} | Closing browser instance [#{i}]..."
					@browsers[i].close rescue nil
					search_status = "#{Time.now} | Amazon search [#{batch_number}] with browser(#{i}) ended with status: #{!@error}"
					@completed.push search_status
					log @main_log, search_status
				end
			end
			@threads.push new
		end
		counter = 0
		loop do
			if @completed.count == @data_groups.count
				puts(log @main_log, "All searches complete!").green
				break
			end
			if counter > 300
				puts(log @main_log, "Counter reached before all searches were completed.").red
				break
			end
			sleep 1
		end
	rescue Interrupt
		puts(log @main_log, "\n#{Time.now} | User pressed Ctrl+C").yellow
		# binding.pry
	rescue => e
		puts(report_error("Encountered error during Rake:amazon", e)).red
		# binding.pry
	ensure
		@threads.each {|t| t.join(1)}
		@browsers.each { |b| b.close rescue nil}
		headless.destroy if @headless
	end
end

desc 'Creates the finalized spreadsheet from all the other spreadsheets'
task :create_spreadsheet do
	puts "#{Time.now.to_s.yellow} | Opening workbook..."
	workbook = create_master_spreadsheet
	open_file(workbook)
end

desc 'Creates a master log file from all of the other logs'
task :create_log do
	puts "#{Time.now.to_s.yellow} | Creating master logs"
	@all_runs_log = create_master_log
	log @main_log, "Logfile generated at this location:\n#{@all_runs_log}\n"
end

desc 'Pusbullet file results'
task :pushbullet_files do
	puts "#{Time.now.to_s.yellow} | Sending files via pushbullet"
	begin
		Dir.glob('results/*').each do |file|
			if File.basename(file).include?(@run_stamp)
				pushbullet_file_to_all(File.basename(file), file, "", @chrome)
			end
		end
	rescue Exception => e
		# puts e.message
		# puts e.backtrace
		puts log @main_log, "Encountered error during pushbullet, probably has to do with stupid windows pushbullet issues"
	end
end

desc 'Report total time'
task :finish do
	puts "#{Time.now.to_s.yellow} | Finishing up"
	begin
		title = "Product scraping complete on #{@computer}"
		message << @errors.empty? ? "Process completed with status no errors!".green : "Process completed but contained errors!".red
		message << "\nTotal processing time: #{seconds_to_string(Time.now - @start_time)}"
		puts log @main_log, "\n#{Time.now} | \n#{message}"
		pushbullet_note_to_all(title, message, @chrome)
		# puts "Opening log file: #{@master_log}"
		# sleep 3
		# open_file(@master_log)
		no_dots
	rescue Exception => e
		# puts e.message
		# puts e.backtrace
		puts log @main_log, "Encountered error during report total time, probably has to do with stupid windows pushbullet issues"
	end
end

at_exit do
	puts "#{Time.now.to_s.yellow} | Performing at_exit stuff"
	log_errors unless @errors.nil?
	# binding.pry
end
