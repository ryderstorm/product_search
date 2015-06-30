unless File.exist?('secret/secret.txt')
	puts "Secret.txt doesn't exist and application cannot continue."
	exit
end

@root_folder = File.absolute_path(File.dirname(__FILE__))
Dir.mkdir('results') unless Dir.exist?('results')
Dir.mkdir('temp') unless Dir.exist?('temp')

require_relative 'libraries/main.rb'
# require_relative 'libraries/digital_ocean.rb'
require_relative 'libraries/pushbullet.rb'
require_relative 'libraries/amazon.rb'

dots
update_path # update path to include chromedriver
init_variables

puts "Root folder = #{@root_folder}"
puts "Running on [#{@computer}] with [#{@cores}] cores"
puts "Runstamp = #{@run_stamp}"
@main_log = @root_folder + "/temp/main_log_#{@run_stamp}.txt"
File.write(@main_log, "#{Time.now} | Creating logfile for run #{@run_stamp}\n")
puts "Main log = #{@main_log}"

#run tasks
task default: :run_all

task run_all: %i(amazon create_log create_spreadsheet pushbullet_files finish)

desc 'Search amazon for the specified skus'
task :amazon do
	begin
		puts "\n#{Time.now} | Starting Amazon search..."
		# @amazon_data = @computer.include?('digital-ocean') ? File.absolute_path('data/amazon.xlsx') : File.absolute_path('data/amazon_test.xlsx')
		@amazon_data = @root_folder + ('/data/amazon_test_big.xlsx')
		@amazon_products = []
		data_groups = read_amazon_data(@group_size)
		log @main_log, "#{Time.now} | Number of data groups: #{data_groups.count}\n"
		if @headless
			log @main_log, "#{Time.now} | Running headless\n"
			headless = Headless.new
			headless.start
		end
		@threads = []
		@completed = []
		@browsers = Array.new(data_groups.count)
		data_groups.each_with_index do |data, i|
			batch_number = i.to_s.rjust(data_groups.count.to_s.length, '0')
			sleep 1 while !free_core
			sleep 2
			break unless @success
			new = Thread.new do
				begin
					puts "\n#{Time.now} | Amazon search [#{batch_number}] of [#{data_groups.count-1}] starting...\n\tCreating browser instance #{batch_number}"
					@browsers[i] = Watir::Browser.new :chrome
					amazon_search(@browsers[i], data, batch_number)
				rescue => e
					puts "\n#{Time.now} | Encountered error during Rake:amazon"
					puts e
					puts e.backtrace
				ensure
					# puts "\n#{Time.now} | Closing browser instance #{batch_number}"
					@browsers[i].close rescue nil
					search_status = "\n#{Time.now} | Amazon search [#{batch_number}] with browser(#{i}) ended with status: #{@success}"
					@completed.push search_status
					puts search_status
				end
			end
			@threads.push new
		end
		counter = 0
		loop do
			if @completed.count == data_groups.count
				puts "All searches complete!"
				break
			end
			if counter > 300
				puts "Counter reached before all searches were completed."
				break
			end
		end
	ensure
		@threads.each {|t| t.join(1)}
		@browsers.each { |b| b.close rescue nil}
		headless.destroy if @headless
	end
end

desc 'Creates the finalized spreadsheet from all the other spreadsheets'
task :create_spreadsheet do
	workbook = create_master_spreadsheet
	puts "Opening workbook..."
	open_file(workbook)
end

desc 'Creates a master log file from all of the other logs'
task :create_log do
	@master_log = create_master_log
	puts "\nLogfile generated at this location:\n#{@master_log}\n"
end

desc 'Pusbullet file results'
task :pushbullet_files do
	begin
		Dir.glob('results/*').each do |file|
			if File.basename(file).include?(@run_stamp)
				pushbullet_file_to_all(File.basename(file), file, "", @chrome)
			end
		end
	rescue Exception => e
		# puts e.message
		# puts e.backtrace
		puts "\n======================\nEncountered error during pushbullet, probably has to do with stupid windows pushbullet issues"
	end
end

desc 'Report total time'
task :finish do
	begin
		title = "Product scraping complete on #{@computer}"
		message = "Process completed with status of #{@success ? "success" : "failure"}"
		message << "\nTotal processing time: #{seconds_to_string(Time.now - @start_time)}"
		puts "\n#{Time.now} | \n#{message}"
		pushbullet_note_to_all(title, message, @chrome)
		puts "Opening log file: #{@main_log}"
		sleep 3
		open_file(@main_log)
		no_dots
	rescue Exception => e
		# puts e.message
		# puts e.backtrace
		puts "\n======================\nEncountered error during report total time, probably has to do with stupid windows pushbullet issues"
	end
end
