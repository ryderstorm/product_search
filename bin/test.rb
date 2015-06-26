# require_relative "../libraries/main.rb"
# require_relative "../libraries/amazon.rb"
require 'pry'
require 'pry-byebug'
require 'rubyXL'
require 'awesome_print'

@root_folder = "/home/damien"

def create_master_spreadsheet
	all_data = {}
	master_wb = RubyXL::Workbook.new
	master_wb[0].sheet_name = 'Summary'
	puts "starting column creation"
	binding.pry

rescue Exception => e
	@error_info = e
	puts "Encoutered the following error:"
	puts e.message
	puts e.backtrace
ensure
	binding.pry
end

create_master_spreadsheet
puts "exiting..."
