require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require 'pry'
require 'pry-byebug'
require 'open-uri'
require 'facter'

# add chromedriver location to PATH
if ENV['PATH'].include?("\\")
	ENV['PATH'] = ENV['PATH'] + ":#{@root_folder}/setup"
else
	ENV['PATH'] = ENV['PATH'] + ";#{@root_folder}/setup".gsub("/","\\")
end

def init_variables
	@start_time = Time.now
	@run_stamp = tstamp
	@group_size = 2
	@success = true
	@cores = Facter.value('processors')['count']
	@computer = Socket.gethostname
	@headless = false
	@headless = true if @computer == 'ryderstorm-amazon_search-1580844'
	@headless = true if @computer.include?('testing-worker-linux-docker')
	@headless = true if @computer.include?('digital-ocean')
	@secrets = parse_secrets(File.absolute_path('secret/secret.txt'))
end

class Product
	attr_accessor :model, :upc, :name, :asin, :search_term, :search_link, :number_of_results, :item_link, :title, :price, :features, :description, :details, :reviews_average, :reviews_link, :reviews_total, :questions_total, :answers_total, :search_screenshot, :info

	def initialize(info)
		@info = info
	end

	def display
		all_data = {}
		header = "Information for #{@info}:"
		puts header
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
			puts "\t#{current_header}: #{value}"
			all_data.store header, value
		end
		return all_data
	end

	def headers
		['Model', 'UPC', 'Name', 'ASIN', 'Search Term', 'Search Link', 'Number of Results', 'Item Link', 'Title', 'Price', 'Features', 'Description', 'Details', 'Reviews Average', 'Reviews Link', 'Reviews Total', 'Questions Total', 'Answers Total']
	end
end

def free_core
	return (Thread.list.count <= 2 ? true : false) if @cores == 1
	@cores > Thread.list.count - 1
end

def read_amazon_data(group_size = 25)
	asins = RubyXL::Parser.parse(@amazon_data).first.extract_data
	asins.delete_if { |a| a.to_s == "[nil, nil, nil, nil]" }
	asins.delete_at(0)
	groups = []
	while asins.count > 0
		groups.push asins.slice!(0, group_size.to_i)
	end
	groups
end

def tstamp
	Time.now.strftime("%Y%m%d%H%M%S").to_s
end

def dots
	@dots = Thread.new {loop {print ".";sleep 0.3333}}
	@dots
end

def no_dots
	unless @dots.nil?
		Thread.kill(@dots)
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

def error_report(e)
	message = ""
	message << "\n!!!!!!!!!!!!!!!!!!!!!\nAn error occurred!\n!!!!!!!!!!!!!!!!!!!!!\n"
	message << "\nCurrent computer: #{@computer}"
	message << "\nCurrent time: #{Time.now}"
	message << "\nTime since application start: #{seconds_to_string(Time.now - @start_time)}"
	# message << "\nURL at time of error:\n#{url}" unless url.nil?
	message << "\nError message contents:"
	message << "\n#{e.message}"
	e.backtrace.each { |trace| message << "\n\t#{trace}" }
	message << "\n\n!!!!!!!!!!!!!!!!!!!!!\n"
	return message
	# if url.nil?
	# 	pushbullet_note_to_all("An error has occurred in the automation!", message)
	# else
	# 	pushbullet_link_to_all("An error has occurred in the automation!", url, message)
	# end
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

def log(file, message)
	File.open(file, "a") do |f|
		if message[0] == "\t"
				f.puts message
		else
			f.puts "#{Time.now} | #{message}"
		end
	end
	puts message
	message
end

def create_master_log
	logs = Dir.glob(@root_folder + "/temp/**/*runlog*#{@run_stamp}*")
	master_log = "#{@root_folder}/results/master_log_#{@run_stamp}.txt"
	logs.sort.each do |log|
		File.open(master_log, "a") do |f|
			f.puts File.read(log)
		end
	end
	File.absolute_path(master_log)
end

def create_master_spreadsheet
	all_data = {}
	master_wb = RubyXL::Workbook.new
	master_wb[0].sheet_name = 'Summary'
	puts "starting column creation"
	binding.pry
	puts "finished create_master_spreadsheet"
rescue Exception => e
	@error_info = e
	puts "Encoutered the following error:"
	puts e.message
	puts e.backtrace
# ensure
# 	binding.pry
end
