unless File.exist?('secret/secret.txt')
	puts "Secret.txt doesn't exist and application cannot continue."
	exit
end

@root_folder = File.absolute_path(File.dirname(__FILE__))
Dir.mkdir('results') unless Dir.exist?('results')
Dir.mkdir('temp') unless Dir.exist?('temp')

require_relative 'libraries/main.rb'
require_relative 'libraries/digital_ocean.rb'
require_relative 'libraries/pushbullet.rb'
require_relative 'libraries/amazon.rb'

dots
init_variables

puts "Root folder = #{@root_folder}"
puts "Running on [#{@computer}] with [#{@cores}] cores"
puts "Runstamp = #{@run_stamp}"

#run tasks
task default: :run_all

task run_all: %i(amazon create_log pushbullet_files finish)

desc 'Search amazon for the specified skus'
task :amazon do
	begin
		puts "\n#{Time.now} | Starting Amazon search..."
		# @amazon_data = @computer.include?('digital-ocean') ? File.absolute_path('data/amazon.xlsx') : File.absolute_path('data/amazon_test.xlsx')
		@amazon_data = @root_folder + ('/data/amazon.xlsx')
		if @headless
			headless = Headless.new
			headless.start
		end
		data_groups = read_amazon_data(@group_size)
		threads = []
		browsers = Array.new(data_groups.count)
		data_groups.each_with_index do |data, i|
			batch_number = i.to_s.rjust(data_groups.count.to_s.length, '0')
			sleep 1 while !free_core
			break unless @success
			puts "\n#{Time.now} | Amazon search [#{batch_number}] of [#{data_groups.count-1}] starting..."
			new = Thread.new do
				begin
					puts "\n#{Time.now} | Creating browser instance #{batch_number}"
					browsers[i] = Watir::Browser.new
					amazon_search(browsers[i], data, batch_number)
				rescue Exception => e
					puts "\n#{Time.now} | Encountered error during Rake:amazon"
					puts e
					puts e.backtrace
				ensure
					puts "\n#{Time.now} | Closing browser instance #{batch_number}"
					browsers[i].close rescue nil
					puts "\n#{Time.now} | Amazon search [#{i}] ended with status: #{@success}"
				end
			end
			threads.push new
		end
	ensure
		threads.each {|t| t.join(5)}
		headless.destroy if @headless
	end
end

desc 'Creates the finalized spreadsheet from all the other spreadsheets'
task :create_spreadsheet do
	create_master_spreadsheet
end

desc 'Creates a master log file from all of the other logs'
task :create_log do
	system("s #{create_master_log}")
end

desc 'Pusbullet file results'
task :pushbullet_files do
	Dir.glob('results/*').each do |file|
		if File.basename(file).include?(@run_stamp)
			pushbullet_file_to_all(File.basename(file), file, "")
		end
	end
end

desc 'Report total time'
task :finish do
	title = "Product scraping complete on #{@computer}"
	message = "Process completed with status of #{@success ? "success" : "failure"}"
	message << "\nTotal processing time: #{seconds_to_string(Time.now - @start_time)}"
	no_dots
	puts "\n#{Time.now} | \n#{message}"
	pushbullet_note_to_all(title, message)
end
