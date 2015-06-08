
require 'watir-webdriver'
# require 'awesome_print'

task default:'amazon_search' 

desc 'Search amazon for the specified skus'
task :amazon_search do

	@error = false
	begin
		def send_enter
			@browser.send_keys :enter
		end

		skus = File.read('amazon_skus.txt').split("\n")

		browser = Watir::Browser.new
		@browser = browser
		browser.window.resize_to(900, 1000)
		browser.window.move_to(0, 0)
		browser.goto 'http://www.amazon.com'
		results = []

		searchbox = browser.text_field(id:'twotabsearchtextbox')
		skus.each_with_index do |sku, i|
			puts "processing sku [#{sku}]"
			searchbox.set sku
			send_enter
			sleep 1
			browser.div(id:'navFooter').wait_until_present
			if browser.element(id:'noResultsTitle').present?
				results.push "#{i+1}. | #{sku.center(20)} | NO RESULTS FOUND"
				next
			end
			# browser.div(id:'searchTemplate').wait_until_present
			# browser.element(id:'s-result-count').wait_until_present
			num_results = browser.element(id:'s-result-count').text.split('of ').last.split(' results').first
			results.push "#{i+1}. | #{sku.center(20)} | #{num_results.center(10)}"
			browser.li(id:'result_0').flash
		end
		results.each { |r| puts r}
		puts "finished processing"
	rescue Exception => e
		@error = true
		puts "\n!!!!!!!!!!!!!!!!!!!!!\nAn error has occurred:"
		puts e.backtrace.first
		puts "\t#{e.message}"
		puts "!!!!!!!!!!!!!!!!!!!!!\n"
	end
end