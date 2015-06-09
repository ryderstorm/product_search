require './lib.rb'
@start_time = Time.now
puts "Socket.gethostname = #{Socket.gethostname}"
@headless = false
@headless = true if Socket.gethostname == 'ryderstorm-amazon_search-1580844'
@headless = true if Socket.gethostname.include?'testing-worker-linux-docker'

task default: :run_all

task run_all: %i(amazon_search total_time)

desc 'Search amazon for the specified skus'
task :amazon_search do
	amazon_search
end

task :total_time do
	puts "\n===============\nTotal processing time: #{seconds_to_string(Time.now - @start_time)}" 
end