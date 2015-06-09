
require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require './amazon_search.rb'
require 'pry'
require 'open-uri'

def send_enter	
	@browser.send_keys :enter
end

def read_workbook
	@workbook = RubyXL::Parser.parse('data.xlsx')
end

def tstamp
	Time.now.strftime("%Y.%m.%d-%H.%M.%S").to_s
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
	complete_name = "#{@temp_folder}/#{filename}_#{tstamp}.png"
	@browser.screenshot.save complete_name
	complete_name
end

def error_report(e)
	puts "\n!!!!!!!!!!!!!!!!!!!!!\nAn error has occurred:"
	puts "#{e.message}"
	(0..8).each { |i| puts "\t" + e.backtrace[i] }
	puts "!!!!!!!!!!!!!!!!!!!!!\n"
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

def save_image(name, src)
	extension = src.split('.').last
	complete_name = "#{@temp_folder}/#{name}_#{tstamp}.#{extension}"
	File.open(complete_name, 'wb') do |f|
	  f.write open(src).read
	end
	complete_name
end