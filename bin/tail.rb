require 'pry'
loop do
	completed = 0
	successful = 0
	stamps = []
	all_logs = Dir.glob("**/temp/**/*runlog*")
	all_logs.each{ |log| stamps.push(File.basename(log).split("_")[2])}
	run_stamp = stamps.uniq.sort.last
	logs = Dir.glob("**/temp/**/*runlog*#{run_stamp}*")
	in_progress = []
	logs.each {|log| in_progress.push log unless File.read(log).include?("Closing resources") }
	in_progress.each do |log|
		puts log
		contents = `tail -n 2 #{File.absolute_path(log)}`
		contents.split.each{ |c| puts "\t#{c}"}
	end

	logs.each do |log|
		contents = File.read(log)
		if contents.include?("Closing resources")
			completed += 1 
			successful += 1 if contents.split.last.include?("true")
		end
	end

	puts "#{completed} of #{logs.count} batches have completed"
	puts "#{successful} of #{logs.count} batches were successful"
	puts "Press enter to generate new status report, or type exit and press enter to exit"
	response = gets.chomp
	exit if response = 'exit'
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
