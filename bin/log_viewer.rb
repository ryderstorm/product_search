require 'sinatra'
require 'haml'
require 'sass'
require 'tilt/haml'
$root_folder = File.expand_path(File.dirname(__FILE__))[0..-5]
require "#{$root_folder}/libraries/main.rb"
puts "\n#{local_time} | Log file server has started with root folder: #{$root_folder.light_red}"
set :logging, false
get '/' do
	haml :index
end

get '/terminate' do
	puts "Shutting down Sinatra via /terminate route...".light_red
	Sinatra::Application.quit!
end

get '/info' do
	"#{request.base_url}<br>#{request.fullpath}<br>#{request.host}"
end

def get_logs
	status = []
	main_log_content = []
	page_content = []
	main_logs = Dir.glob($root_folder + "/results/**/*#{$run_stamp}.txt").sort
	current_log = main_logs.last
	contents = File.read(current_log).split("\n")
	start_time = Time.parse(contents[0])#.utc.getlocal(-14400)
	main_log_content.push ""
	main_log_content.push "=========================="
	main_log_content.push "Main log | #{File.basename(current_log)}"
	contents.each { |c| main_log_content.push c }
	data_groups = contents[3].split("Number of data groups: ").last
	completed = 0
	successful = 0
	failed = 0
	stamps = []
	logs = Dir.glob($root_folder + "/temp/**/*.txt")
	logs.each{ |log| stamps.push(File.basename(log).split("_")[2])}
	run_stamp = stamps.uniq.sort.last[0..-5]
	status.push "Using run_stamp [#{run_stamp}]"
	logs.delete_if{|log| !File.basename(log).include?(run_stamp) or File.basename(log).include?('product_log')}
	in_progress = []
	logs.each {|log| in_progress.push log unless File.read(log).include?("Closing resources") }
	in_progress.sort.each do |log|
		page_content.push " "
		page_content.push "=========================="
		page_content.push "#{File.basename(log)}"
		contents = File.read(File.absolute_path(log)).split("\n").last(10)
		contents.each{ |c| page_content.push "\t#{c}"}
	end
	logs.each do |log|
		contents = File.read(log)
		if contents.include?("Closing resources")
			completed += 1
			successful += 1 if contents.split.last.include?("true")
			failed += 1 if contents.split.last.include?("false")
		end
	end
	status.push "=============================="
	if main_log_content.to_s.include? "Product scraping complete"
		status.push "Current run completed at #{main_log_content[-2].split(" | ").first}"
	else
		status.push "Test has been running for #{seconds_to_string(Time.parse(local_time.uncolorize) - start_time)}"
	end
	status.push "There are #{logs.count} logs available of #{data_groups} total runs"
	status.push "#{completed} / #{(completed.to_f / data_groups.to_i * 100.0).round(2)}% have completed"
	unless completed == 0
		status.push "#{successful} / #{(successful.to_f / completed * 100.0).round(2)}% successful so far"
		status.push "#{failed} / #{(failed.to_f / completed * 100.0).round(2)}% failed so far"
	end
	product_status = File.read($root_folder + "/temp/product_log_#{run_stamp}.txt").split('|')
	status.push "#{(product_status.first.to_i / product_status.last.to_f * 100).round(2)}% | #{product_status.first} of #{product_status.last} total products processed so far"

	all_content = status + main_log_content + page_content
	return all_content.join("<br>")
end