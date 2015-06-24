require 'pry'
stamps = []
logs = Dir.glob("**/temp/**/*runlog*")
logs.each{ |log| stamps.push(File.basename(log).split("_")[2])}
run_stamp = stamps.uniq.sort.last
begin
	logs = []
	current_logs = []
	threads = []
	old_logs = []
	loop do
		logs = Dir.glob("**/temp/**/*runlog*#{run_stamp}*")
		current_logs = []
		threads = []
		logs.each {|log| current_logs.push log unless File.read(log).include?("Closing resources") }
		log_list = ""
		current_logs.each{ |log| log_list << "#{File.absolute_path(log)} " }
		next if current_logs == old_logs
		command = "tail --lines=4 -f #{log_list}"
		tail = Thread.new{system(command)}
		threads.push tail
		sleep 5
		old_logs = current_logs
		return if current_logs.empty?
	end
ensure
	threads.each {|t| t.join}
end