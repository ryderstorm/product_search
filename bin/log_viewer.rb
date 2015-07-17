require 'sinatra'
require 'haml'
require 'sass'
require 'tilt/haml'
folder = ENV["C9_HOSTNAME"].nil? ? 'amazon_search' : 'workspace'
$root_folder = File.expand_path(Dir.glob("/**/#{folder}").first)
require "#{$root_folder}/libraries/main.rb"
puts "\n#{local_time} | Log file server has started with root folder: #{$root_folder.light_red}"
# binding.pry
# set :public_folder, $root_folder
def get_files
	run_stamp = get_run_stamp
	Dir.glob($root_folder + "/**/*#{run_stamp}*.*")
end

def file_links
	file_list = []
	get_files.each{|f| file_list.push "<a href='/serve_file/#{File.absolute_path(f).gsub('/', '|')}'>#{File.basename(f)}</a>"}
	file_list.join("<br>")
end

def get_run_stamp
	stamps = []
	logs = Dir.glob($root_folder + "/results/main_log*.txt")
	logs.each{ |log| stamps.push(File.basename(log).split("_")[2])}
	stamps.uniq.sort.last[0..-5]
end


def create_status_log
	status = []
	main_log_content = []
	page_content = []
	run_stamp = get_run_stamp
	status.push "Using run_stamp [#{run_stamp}]"
	main_log = Dir.glob($root_folder + "/results/main_log_#{run_stamp}.txt").first
	contents = File.read(main_log).split("\n")
	start_time = Time.parse(contents[0])#.utc.getlocal(-14400)
	main_log_content.push ""
	main_log_content.push "=========================="
	main_log_content.push "Main log | #{File.basename(main_log)}"
	contents.each { |c| main_log_content.push c }
	data_groups = contents[5].split("data groups: ").last
	completed = 0
	successful = 0
	failed = 0
	all_logs = Dir.glob($root_folder + "/**/*#{run_stamp}*.txt")
	logs = Dir.glob($root_folder + "/temp/**/*runlog*#{run_stamp}*.txt")
	in_progress = []
	logs.each do |log|
		contents = File.read(log)
		if contents.include?("Closing resources")
			completed += 1
			successful += 1 if contents.split.last.include?("successful")
			failed += 1 if contents.split.last.include?("failure")
		else
			in_progress.push log
		end
	end
	in_progress.sort.each do |log|
		page_content.push " "
		page_content.push "=========================="
		page_content.push "#{File.basename(log)}"
		contents = File.read(File.absolute_path(log)).split("\n").last(10)
		contents.each{ |c| page_content.push "\t#{c}"}
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

get '/serve_file/:file' do
	file = params['file'].gsub('|', '/')
	send_file(file)
end

get '/file_list' do
	haml :file_list
end

get '/serve_test' do
	puts Dir.pwd
	# send_file($root_folder + '/temp/output.txt')
	puts File.absolute_path('serve_test.txt')
	send_file(File.absolute_path('serve_test.txt'))
end

