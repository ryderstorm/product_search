
require 'watir-webdriver'
require 'rubyXL'
require './amazon_search.rb'

def send_enter
	@browser.send_keys :enter
end

def read_workbook
	@workbook = RubyXL::Parser.parse('data.xlsx')
end