require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require 'pry'
require 'pry-byebug'
require 'open-uri'
require 'facter'

def init_variables
	@computer = Socket.gethostname
	@start_time = Time.now
	@run_stamp = tstamp
	if @computer.include?('digital-ocean') 
		@amazon_data = File.absolute_path('data/amazon.xlsx')
		# @amazon_data = File.absolute_path('data/amazon_test_big.xlsx')
		@group_size = 5
	else
		@amazon_data = File.absolute_path('data/amazon_test.xlsx')
		@group_size = 2
	end
	@success = true
	@cores = Facter.value('processors')['count']
	@headless = true
	@headless = false if @computer == 'GSOD-DSTORM'
	@headless = true if @computer == 'ryderstorm-amazon_search-1580844'
	@headless = true if @computer.include?('testing-worker-linux-docker')
	@headless = true if @computer.include?('digital-ocean')
	@secrets = parse_secrets(File.absolute_path('secret/secret.txt'))
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
	# 	pushbullet_note_to_all("An error has occurred in the automation!", message, @chrome)
	# else
	# 	pushbullet_link_to_all("An error has occurred in the automation!", url, message, @chrome)
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
	# puts message
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
	wb_location = "#{@root_folder}/results/amazon_products_#{@run_stamp}.xlsx"
	puts log @main_log, "#{Time.now} | Starting creation of results workbook\n\t#{wb_location}"
	all_data = {}
	master_wb = RubyXL::Workbook.new
	summary_sheet = master_wb[0]
	summary_sheet.sheet_name = 'Summary'
	@amazon_products.first.headers.each_with_index do |h, i|
		summary_sheet.add_cell(0, i, h)
	end
	@amazon_products.each_with_index do |product, i|
		puts log @main_log, "#{Time.now} | Processing product [#{i+1}] of [#{@amazon_products.count}]: #{product.search_term}"
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
				File.open(File.expand_path('~/.profile'), 'a') { |f| f.puts("# Adding path to chromedriver\nPATH=$PATH;#{chromedriver_location}")}
			end
			ENV['PATH'] = ENV['PATH'] + ":#{@root_folder}/setup"
			puts "~/.profile has been updated to include chromedriver and the local path has been updated."
			# exit
		end
	end
end

def open_file(file)
	ENV['OS'].nil? ? system("gnome-open #{file}") : system("start #{file}")
end

def report_error(note, error)
	error_message = "\n#{Time.now}"
	error_message << "\n\t#{note}\n\tClass: #{error.class}\n\tMessage: #{error.message}"
	error.backtrace.each { |i| error_message << "\n\t#{i}" }
  (Thread.current[:errors] ||= []) << "#{error_message}"
  @errors << "#{error_message}"
  error_message
end

def log_errors
	puts "#{Time.now} | logging errors to file..."
	counter = 0
	binding.pry
  File.open(@error_log, 'a') do |f|
    (Thread.current[:errors] ||= []).each do |error|
    	counter += 1
      f.puts error
    end
  end
  puts "#{Time.now} | added #{counter} errors to #{@error_log}"
end