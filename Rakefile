require './lib.rb'

task default:'amazon_search' 

desc 'Search amazon for the specified skus'
task :amazon_search do
	read_workbook
	data = @workbook.first.extract_data
	puts data
	amazon_search
end