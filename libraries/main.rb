require 'awesome_print'
require 'colorize'
require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require 'pry'
require 'pry-byebug'
require 'open-uri'
require 'facter'

def init_variables
	if @root_folder.nil?
		@root_folder = File.expand_path(File.dirname(__FILE__)).sub('/libraries', '')
		puts "Setting @root_folder from within init_variables to: ".yellow + @root_folder.red
	end
	# @dots = nil
	@computer = Socket.gethostname
	@start_time = Time.parse(local_time.uncolorize)
	@run_stamp = tstamp
	@amazon_data = File.absolute_path(Dir.glob(@root_folder + '/data/active/amazon*').first)
	@group_size = 5
	@cores = Facter.value('processors')['count']
	# @remote_ip = open('http://whatismyip.akamai.com/').read.strip # was working but stopped, keeping as reference
	@remote_ip = open('http://icanhazip.com/').read.strip
	@headless = true
	@headless = false if @computer == 'GSOD-DSTORM'
	@headless = true if @computer == 'ryderstorm-amazon_search-1580844'
	@headless = true if @computer.include?('testing-worker-linux-docker')
	@headless = true if @computer.include?('digital-ocean')
	@secrets = parse_secrets(File.absolute_path('secret/secret.txt'))
	@errors = []
	@main_log = @root_folder + "/results/main_log_#{@run_stamp}.txt"
	@error_log = @root_folder + "/results/error_log_#{@run_stamp}.txt"
	@product_log = @root_folder + "/temp/product_log_#{@run_stamp}.txt"
	puts "Root folder = ".blue + @root_folder.yellow
	puts "Runstamp = ".blue + @run_stamp.yellow
	puts "Main log = ".blue + @main_log.yellow
	puts "Error log = ".blue + @error_log.yellow
	puts "Running on [".blue + @computer.yellow + "] with [".blue + @cores.to_s.yellow + "] cores.".blue
	update_path # update path to include chromedriver
end

class Product
	attr_accessor :model, :upc, :name, :asin, :search_term, :search_link, :number_of_results, :item_link, :title, :price, :features, :description, :details, :reviews_average, :reviews_link, :reviews_total, :questions_total, :answers_total, :search_screenshot, :info

	def initialize(info)
		self.instance_variables.each { |i| i = 'no data'}
		@info = info
	end

	def all_info
		all_data = {}
		header = "Information for #{@info}:"
		# puts header
		all_data.store 'Header', header
		self.instance_variables.each do |v|
			current_header = ''
			self.headers.each do |h|
				if v.to_s.sub('@', '') == h.downcase.gsub(' ', '_')
					current_header = h
					break
				end
			end
			value = self.instance_variable_get(v)
			# puts "\t#{current_header}: #{value}"
			all_data.store header, value
		end
		return all_data
	end

	def headers
		['Model', 'UPC', 'Name', 'ASIN', 'Search Term', 'Search Link', 'Number of Results', 'Item Link', 'Title', 'Price', 'Features', 'Description', 'Details', 'Reviews Average', 'Reviews Link', 'Reviews Total', 'Questions Total', 'Answers Total']
	end
end

def free_core
	@cores = 4 if @computer == "GSOD-DSTORM"
	return (Thread.list.count <= 2 ? true : false) if @cores == 1
	@cores > Thread.list.count - 1
end

def read_amazon_data(group_size = 25)
	log "Test data pulled from: " + @amazon_data
	asins = RubyXL::Parser.parse(@amazon_data).first.extract_data
	asins.delete_if { |a| a.to_s == "[nil, nil, nil, nil]" }
	asins.delete_at(0)
	@amazon_product_count = asins.count
	groups = []
	while asins.count > 0
		groups.push asins.slice!(0, group_size.to_i)
	end
	groups
end

def tstamp
	Time.now.utc.getlocal(-14400).strftime("%Y%m%d%H%M%S").to_s
end

def dots
	@dots = Thread.new {loop {print ".";sleep 0.3333}} if @dots.nil?
end

def no_dots
	unless @dots.nil?
		Thread.kill(@dots)
		@dots = nil
		puts ""
	end
end

def take_screenshot(filename = 'screenshot')
	return if @browser.nil?
	complete_name = "#{@temp_folder}/#{filename}_#{tstamp}.png"
	@browser.screenshot.save complete_name
	File.absolute_path(complete_name)
end

def save_image(name, src)
	extension = src.split('.').last
	complete_name = "#{@temp_folder}/#{name}_#{tstamp}.#{extension}"
	File.open(complete_name, 'wb') do |f|
		f.write open(src).read
	end
	File.absolute_path(complete_name)
end

def pluralize(number)
	number == 1 ? (return ""):(return "s")
end

def seconds_to_string(s)
	# d = days, h = hours, m = minutes, s = seconds
	m = (s / 60).floor
	s = (s % 60).floor
	h = (m / 60).floor
	m = m % 60
	d = (h / 24).floor
	h = h % 24

	output = "#{s} second#{pluralize(s)}" if (s > 0)
	output = "#{m} minute#{pluralize(m)}, #{s} second#{pluralize(s)}" if (m > 0)
	output = "#{h} hour#{pluralize(h)}, #{m} minute#{pluralize(m)}, #{s} second#{pluralize(s)}" if (h > 0)
	output = "#{d} day#{pluralize(d)}, #{h} hour#{pluralize(h)}, #{m} minute#{pluralize(m)}, #{s} second#{pluralize(s)}" if (d > 0)

	return output
end

def parse_secrets(secrets_location)
	secrets = {}
	info = File.read(secrets_location).split
	info.each do |i|
		secrets.store(i.split('|').first.to_sym, i.split('|').last)
	end
	secrets
end

def local_time
	# returns the time in Greensboro NC
	Time.now.utc.getlocal(-14400).strftime("%Y-%m-%d %H:%M:%S").yellow
end

def log(file = @main_log, message)
	File.open(file, "a") do |f|
		unless message[0] == "\t"
			message = "#{local_time} | #{message}"
		end
		f.puts message.uncolorize
	end
	message
end

def create_master_log
	logs = Dir.glob(@root_folder + "/temp/**/*runlog*#{@run_stamp}*")
	all_runs_log = "#{@root_folder}/results/all_runs_log_#{@run_stamp}.txt"
	logs.sort.each do |log|
		File.open(all_runs_log, "a") do |f|
			f.puts File.read(log)
		end
	end
	File.absolute_path(all_runs_log)
end

def create_master_spreadsheet
	if @amazon_products.empty?
		puts "No products found! Can't create workbook."
		return
	end
	wb_location = "#{@root_folder}/results/amazon_products_#{@run_stamp}.xlsx"
	puts log "Starting creation of results workbook\n\t#{wb_location.blue}"
	master_wb = RubyXL::Workbook.new
	summary_sheet = master_wb[0]
	summary_sheet.sheet_name = 'Summary'
	@amazon_products.first.headers.each_with_index do |h, i|
		summary_sheet.add_cell(0, i, h)
	end
	@amazon_products.each_with_index do |product, i|
		puts log "Processing product [#{i+1}] of [#{@amazon_products.count}]: #{product.search_term}"
		master_wb.add_worksheet(product.search_term)
		sheet = master_wb[product.search_term]
		product.instance_variables.each_with_index do |variable, j|
			product.headers.each_with_index do |header, k|
				if header.downcase.gsub(' ', '_') == variable.to_s[1..-1]
					value_to_write = product.instance_variable_get(variable)
					if value_to_write.to_s[0..3] == 'http'
						summary_sheet.add_cell(i+1, k, '', "HYPERLINK(\"#{value_to_write}\")")
						summary_sheet[i+1][k].change_font_color('0000CC')
					else
						summary_sheet.add_cell(i+1, k, value_to_write)
					end
					summary_sheet[i+1][k].change_horizontal_alignment('left')
					summary_sheet[i+1][k].change_fill('FF6161') if value_to_write == 'no data'
				end
			end
			sheet.add_cell(j, 0, variable.to_s[1..-1].split('_').each{|word| word.capitalize!}.join(' '))
			value_to_write = product.instance_variable_get(variable)
			if value_to_write.to_s[0..3] == 'http'
				sheet.add_cell(j, 1, '', "HYPERLINK(\"#{value_to_write}\")")
				sheet[j][1].change_font_color('0000CC')
			else
				sheet.add_cell(j, 1, value_to_write)
			end
			sheet[j][1].change_horizontal_alignment('left')
			shee[j][1].change_fill('FF6161') if value_to_write == 'no data'
			sheet.change_column_width(0, 18)
			sheet.change_column_width(1, 150)
		end
	end
rescue Interrupt
	log logfile, "User pressed Ctrl+C during workbook creation"
	binding.pry
rescue => e
	puts report_error("Error encountered during workbook generation", e)
ensure
	master_wb.write(wb_location)
	log @main_log, "Completed creation of results workbook:\n#{wb_location}"
	return wb_location
end

def update_path
	chromedriver_location = @root_folder + "/setup"
	if ENV['PATH'].include?("\\")
		unless ENV['PATH'].include?(chromedriver_location.gsub("/", "\\"))
			puts "Current PATH does not include chromedriver:\n#{ENV['PATH']}"
			ENV['PATH'] = ENV['PATH'] + ";#{@root_folder}/setup".gsub("/","\\")
		end
	else
		unless ENV['PATH'].include?(chromedriver_location)
			puts "Current PATH does not include chromedriver:\n#{ENV['PATH']}"
			unless File.read(File.expand_path('~/.profile')).include?(chromedriver_location)
				File.open(File.expand_path('~/.profile'), 'a') { |f| f.puts("# Adding path to chromedriver\nPATH=$PATH:#{chromedriver_location}")}
			end
			ENV['PATH'] = ENV['PATH'] + ":#{@root_folder}/setup"
			puts "~/.profile has been updated to include chromedriver and the local path has been updated."
			# exit
		end
	end
end

def open_file(file)
	if Socket.gethostname == "ryderstorm-amazon_search-1580844"
		puts "Can't open files on C9!".red
		return
	end
	ENV['OS'].nil? ? system("gnome-open #{file}") : system("start #{file}")
end

def report_error(error, note = ' ')
	error_message = "=======================================================\n".light_red
	error_message << note.light_blue
	error_message << "\nTime: ".ljust(12).yellow + local_time.green
	error_message << "\nComputer: ".ljust(12).yellow + @computer.green unless @computer.nil?
	error_message << "\nClass: ".ljust(12).yellow + error.class.to_s.light_red
	error_message << "\nMessage: ".ljust(12).yellow + error.message.light_red
	error_message << "\nBacktrace: ".ljust(12).yellow + error.backtrace.first.light_red
	error.backtrace[1..-1].each { |i| error_message << "\n           #{i.light_red}" }
  @errors.push "#{error_message}" unless @errors.nil?
  error_message
end

def log_errors
	puts "#{local_time} | Logging #{@errors.count.to_s.red} errors to [#{@error_log.red}]"
	@errors.each{ |error| log(@error_log, error)}
end

def run_remote_search(size = 'small', data_set = 'test')
	new_droplet = create_droplet(size)
	ssh_output = ssh_rake(new_droplet.ip_address, data_set)
	binding.pry
	loop do
		status = open("#{new_droplet.ip_address}:8100").read.strip
		break if status.include?("Current run  with runstamp #{@run_stamp} has completed")
	end
	ensure
	ssh_shutdown(new_droplet.ip_address)
	destroy_droplet(new_droplet)
end

def set_test_data(file_for_testing)
	Dir.glob(@root_folder + '/data/active/*.*').each{ |f| File.delete(f) }
	FileUtils.cp(file_for_testing, @root_folder + '/data/active')
	puts "Set data file to be [#{file_for_testing.yellow}]"
end
