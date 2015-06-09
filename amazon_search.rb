def amazon_search
	@error = false
	begin
		puts "Beginning Amazon Search"
		dots
		temp_folder = "./amazon_temp/#{tstamp}"
		Dir.mkdir(temp_folder)
		skus = File.read('amazon_skus.txt').split("\n")
		if @headless
			headless = Headless.new
			headless.start
		end
		browser = Watir::Browser.new
		@browser = browser
		browser.window.resize_to(900, 1000)
		browser.window.move_to(0, 0)
		browser.goto 'http://www.amazon.com'
		results = []

		searchbox = browser.text_field(id:'twotabsearchtextbox')
		skus.each_with_index do |item, i|
			sku, desc = item.split('|')
			puts "\nprocessing sku [#{sku} | #{desc}]"
			searchbox.set
			send_enter
			sleep 1
			browser.div(id:'navFooter').wait_until_present
			if browser.element(id:'noResultsTitle').present?
				results.push "#{i+1}. | #{sku.center(20)} | #{desc} | NO RESULTS FOUND"
				next
			end
			# browser.div(id:'searchTemplate').wait_until_present
			# browser.element(id:'s-result-count').wait_until_present
			num_results = browser.element(id:'s-result-count').text.split('of ').last.split(' results').first
			results.push "#{i+1}. | #{sku.center(20)} | #{desc} | #{num_results.center(10)}"
			# browser.li(id:'result_0').flash
		end
		no_dots
		puts "\n==============="
		results.each { |r| puts r}
		puts "===============\n"
		puts "finished processing"
	rescue Exception => e
		@error = true
		no_dots
		error_file = "#{temp_folder}/ERROR_#{tstamp}.png"
		browser.screenshot.save error_file
		puts "\n!!!!!!!!!!!!!!!!!!!!!\nAn error has occurred:"
		puts e.backtrace.first
		puts "\t#{e.message}"
		puts "!!!!!!!!!!!!!!!!!!!!!\n"
		puts "Exiting after fail due to error. Screenshot saved as [#{error_file}]"
		binding.pry
	end
	browser.close
	headless.destroy if @headless
	no_dots
	puts "Amazon scrape completed succesfully." unless @error
end
