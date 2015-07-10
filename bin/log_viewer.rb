=begin

take a parameter for the run_stamp
get all the files with the run_stamp
create a div for each window
	read the last 10 lines of that file
	display it
	refresh every 2 seconds

=end

require 'sinatra'
require 'haml'
require 'sass'
require 'require_all'
require 'tilt/haml'
$run_stamp = ARGV[0]
$root_folder = File.expand_path(File.dirname(__FILE__))[0..-5]
puts "Log file server has started with the following parameters:\nRun stamp: #{$run_stamp}\nRoot folder: #{$root_folder}"
get '/' do
	haml :index
	# get_logs
end

get '/terminate' do
	Sinatra::Application.quit!
end

get '/info' do
	"#{request.base_url}<br>#{request.fullpath}<br>#{request.host}"
end

def get_logs
	# puts "#{Time.now} | Getting logs from #{$root_folder}..."
	content = []
	logs = Dir.glob($root_folder + "/results/**/*#{$run_stamp}.txt")
	logs.each do |l|
		# puts "Found file: #{l}"
		content.push "======================================="
		content.push "Contents of #{l}:"
		File.read(l).split("\n").last(20).each { |line| content.push line }
	end
	# puts content
	return content.join("<br>")
end