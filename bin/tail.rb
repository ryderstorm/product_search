require 'pry'
# log_location = @root_folder + "/temp/**/*amazon*runlog*#{@run_stamp}"
log_location = "/home/damien/amazon_search/temp/**/*amazon*runlog*.txt"
logs = Dir.glob(log_location)
master_log = "./master_log"
logs.sort.each do |log|
	File.open(master_log, "a") do |f|
		f.puts File.read(log)
	end
end
binding.pry
system("s #{File.absolute_path(master_log)}")
