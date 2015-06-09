def amazon_search
	@error = false
	begin
		puts "Beginning Amazon Search"
		@temp_folder = "./amazon_temp/#{tstamp}"
		FileUtils.mkdir_p(@temp_folder)
		puts "Temp folder location: #{File.absolute_path(@temp_folder)}"
		dots
		result_urls = []
		result_counts = []
		workbook = RubyXL::Workbook.new
		workbook_location = "#{@temp_folder}/AMAZON_DATA_#{tstamp}.xlsx"
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

		searchbox = browser.text_field(id:'twotabsearchtextbox')
		skus.each_with_index do |item, i|

			#search for the current sku
			sku, desc = item.split('|')
			puts "\nprocessing sku [#{sku} | #{desc}]"
			worksheet = workbook.add_worksheet(sku)
			worksheet.add_cell(0, 0, sku)
			worksheet.add_cell(0, 1, desc)
			searchbox.set sku
			send_enter
			sleep 1
			browser.div(id:'navFooter').wait_until_present
			worksheet.add_cell(1, 0, "Search results URL")
			worksheet.add_cell(1, 1, browser.url)
			worksheet.add_cell(1, 2, take_screenshot("#{sku}_SEARCH_RESULTS"))

			# move on if no results were found
			if browser.element(id:'noresult_countsTitle').present?
				result_counts.push "#{i+1}. | #{sku.center(20)} | #{desc} | NO result_counts FOUND"
				next
			end

			# get the number of results
			search_result_counts = browser.element(id:'s-result-count').text
			if search_result_counts.include?('1 result')
					number_results = 1
			elsif search_result_counts.include?(' of ')
				number_results = search_result_counts.split('of ').last.split(' results').first
			else 
				number_results = search_result_counts.split(' ').first
			end
			worksheet.add_cell(2, 0, "Number of search results")
			worksheet.add_cell(2, 1, number_results)
			worksheet.add_cell(2, 2, save_image("#{sku}_SEARCH_THUMBNAIL", browser.li(id:'result_0').imgs.first.attribute_value('src')))

			# go to the first result
			browser.li(id:'result_0').links.first.click
			sleep 1
			browser.div(id:'navFooter').wait_until_present

			# save the workbook
			worksheet.change_column_width(0, 30) 
			worksheet.change_column_width(1, 30) 
			worksheet.change_column_width(2, 30) 
			workbook.write(workbook_location)
		end
		no_dots
		puts "\n==============="
		result_counts.each { |r| puts r }
		puts "===============\n"
		puts "finished processing"
	rescue Exception => e
		@error = true
		no_dots
		error_file = take_screenshot('ERROR')
		error_report(e)
		puts "Exiting after fail due to error. Screenshot saved as [#{error_file}]"
		binding.pry
	end
	browser.close
	headless.destroy if @headless
	no_dots
	unless @error
		puts "Amazon scrape completed succesfully." 
		system(workbook_location)
	end
end
