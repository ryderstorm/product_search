require 'pry'
require 'awesome_print'
require './libraries/main.rb'

old_log = ''
data_groups = 0
loop do
	main_logs = Dir.glob("**/results/main_log*.txt").sort
	current_log = main_logs.last
	if current_log != old_log
		puts current_log
		contents = File.read(current_log).split("\n")
		ap contents
		time = contents[0]
		puts time
		@start_time = Time.parse(time)
		puts @start_time
		data_groups = contents[2].split("Number of data groups: ").last
		old_log = current_log
	end

	completed = 0
	successful = 0
	failed = 0
	stamps = []
	all_logs = Dir.glob("**/temp/**/*runlog*")
	all_logs.each{ |log| stamps.push(File.basename(log).split("_")[2])}
	run_stamp = stamps.uniq.sort.last
	logs = Dir.glob("**/temp/**/*runlog*#{run_stamp}*")
	in_progress = []
	logs.each {|log| in_progress.push log unless File.read(log).include?("Closing resources") }
	in_progress.sort.each do |log|
		puts "\n#{File.basename(log)}"
		contents = `tail -n 5 #{File.absolute_path(log)}`
		contents.split("\n").each{ |c| puts "\t#{c}"}
	end

	logs.each do |log|
		contents = File.read(log)
		if contents.include?("Closing resources")
			completed += 1 
			successful += 1 if contents.split.last.include?("true")
			failed += 1 if contents.split.last.include?("false")
		end
	end
	puts "\n==============================\n"
	puts "Test has been running for #{seconds_to_string(Time.now - @start_time)}"
	puts "There are #{logs.count} logs available of #{data_groups} total runs"
	puts "#{completed} / #{(completed.to_f / data_groups.to_i * 100.0).round(2)}% have completed"
	unless completed == 0
		puts "#{successful} / #{(successful.to_f / completed * 100.0).round(2)}% successful so far"
		puts "#{failed} / #{(failed.to_f / completed * 100.0).round(2)}% failed so far"
		product_status = File.read(Dir.glob("**/temp/product_log_#{run_stamp}.txt").first).split('|')
		puts "#{product_status.first.to_i / product_status.last.to_f * 100}% | #{product_status.first} of #{product_status.last} total products processed so far"
	end

	# if completed == data_groups
		
	puts "Press enter to generate new status report, or type exit and press enter to exit"
	response = gets.chomp
	exit if response == 'exit'
end
# logs = []
# current_logs = []
# threads = []
# old_logs = []

# logs = Dir.glob("**/temp/**/*runlog*#{run_stamp}*")
# current_logs = []
# threads = []
# log_list = ""
# current_logs.each{ |log| log_list << "#{File.absolute_path(log)} " }
# next if current_logs == old_logs
# command = "tail --lines=4 -f #{log_list}"
# tail = Thread.new{system(command)}
# threads.push tail
# sleep 5
# old_logs = current_logs
# return if current_logs.empty?
