unless File.exist?('secret/secret.txt')
	puts "Secret.txt doesn't exist and application cannot continue."
	exit
end
require_relative 'libraries/main.rb'
require_relative 'libraries/digital_ocean.rb'
require_relative 'libraries/pushbullet.rb'
@start_time = Time.now
@run_stamp = tstamp
@root_folder = File.absolute_path(File.dirname(__FILE__))
@results_folder = @root_folder + "/results/" 
puts "Root folder = #{@root_folder}"

#run tasks
task default: :run_all

task run_all: %i(amazon pushbullet total_time)

desc 'Search amazon for the specified skus'
task :amazon do
	load 'bin/amazon_search.rb'
end

desc 'Pusbullet file results'
task :pushbullet do
	Dir.glob('results/*').each do |file|
		if File.basename(file).include?(@run_stamp)
			pushbullet_file_to_all(File.basename(file), file, "")
		end
	end
end

desc 'Report total time'
task :total_time do
	puts "\n===============\nTotal processing time: #{seconds_to_string(Time.now - @start_time)}"
end