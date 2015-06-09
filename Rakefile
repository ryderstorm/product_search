require './lib.rb'
@headless = false
@headless = true if Socket.gethostname == 'ryderstorm-amazon_search-1580844'

task default:'amazon_search' 

desc 'Search amazon for the specified skus'
task :amazon_search do
	read_workbook
	data = @workbook.first.extract_data
	puts data
	amazon_search
end