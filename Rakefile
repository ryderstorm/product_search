unless File.exist?('secret/secret.txt')
	puts "Secret.txt doesn't exist and application cannot continue."
	exit
end

require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require 'pry'
require 'open-uri'
require 'facter'

@root_folder = File.absolute_path(File.dirname(__FILE__))

require_relative 'libraries/main.rb'
require_relative 'libraries/digital_ocean.rb'
require_relative 'libraries/pushbullet.rb'
require_relative 'libraries/amazon.rb'

init_variables

puts "Root folder = #{@root_folder}"
puts "Running on [#{@computer}] with [#{@cores}] cores"

#run tasks
task default: :run_all

task run_all: %i(amazon pushbullet_files finish)

desc 'Search amazon for the specified skus'
task :amazon do
	data_groups = read_amazon_data(@group_size)
	data_groups.each_with_index do |data, i|
		puts "Amazon search [#{i+1} of #{data_groups.count}] starting..."
		result = amazon_search(data, 1)
		puts "Amazon search [#{i+1} of #{data_groups.count}] ended with status: #{result}"
		unless result
			@success = false
			break
		end
	end
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
	puts message
	pushbullet_note_to_all(title, message)
end