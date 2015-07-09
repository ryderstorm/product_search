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

$run_stamp = ARGV[0]
$run_stamp = '20150629210529'
$root_folder = File.expand_path(File.dirname(__FILE__))[0..-5]
puts "$root_folder from log_viewer.rb = #{$root_folder}"
get '/' do
	haml :index
end
