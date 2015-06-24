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
	all_workbooks = Dir.glob(@root_folder + "/temp/**/*.xlsx").sort
	all_workbooks.each_with_index do |wb, i|
		current_wb = RubyXL::Parser.parse(wb)
		puts "parsing #{i} of #{all_workbooks.count - 1} | #{current_wb.name}"
		current_wb[1..-1].each do |sheet|
			sheet_data = sheet.extract_data
			all_data.store(sheet_data[0][0].to_sym, sheet_data)
		end
	end
rescue Exception => e
	puts "Encoutered the following error:"
	puts e.message
	puts e.backtrace
	binding.pry
end

create_master_spreadsheet
puts "exiting..."
