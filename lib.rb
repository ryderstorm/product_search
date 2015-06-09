
require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require './amazon_search.rb'
require 'pry'

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
