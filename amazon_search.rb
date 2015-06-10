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
		workbook[0].sheet_name = 'Summary'
		workbook[0].change_column_width(0, 50)
		skus = File.read('amazon_skus.txt').split("\n")
		skus.each_with_index { |sku, i| workbook[0].add_cell(i, 0, sku)}
		workbook.write(workbook_location)

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
			worksheet.add_cell(1, 1, '', "HYPERLINK(\"#{browser.url}\")")
			worksheet[1][1].change_font_color('0000CC')
			image = take_screenshot("#{sku}_SEARCH_RESULTS")
			worksheet.add_cell(1, 2, '', "HYPERLINK(\"#{image}\")")
			worksheet[1][2].change_font_color('0000CC')
			if browser.element(id:'noresult_countsTitle').present?
				# move on if no results were found
				result_counts.push "#{i+1}. | #{sku.center(20)} | #{desc} | NO result_counts FOUND"
				no_results = true
			else
				# get the number of results
				no_results = false
				search_result_counts = browser.element(id:'s-result-count').text
				if search_result_counts.include?('1 result')
						number_results = 1
				elsif search_result_counts.include?(' of ')
					number_results = search_result_counts.split('of ').last.split(' results').first
				else 
					number_results = search_result_counts.split(' ').first
				end
			end
			worksheet.add_cell(2, 0, "Number of search results")
			worksheet.add_cell(2, 1, number_results)
			image = save_image("#{sku}_SEARCH_THUMBNAIL", browser.li(id:'result_0').imgs.first.attribute_value('src'))
			worksheet.add_cell(2, 2, '', "HYPERLINK(\"#{image}\")")
			worksheet[2][2].change_font_color('0000CC')

			unless no_results
				# go to the first result
				browser.li(id:'result_0').links.first.click
				sleep 1
				browser.div(id:'navFooter').wait_until_present

				# record the name, features, desc, details
				worksheet.add_cell(3, 0, "Product Name")
				if browser.span(id:'productTitle').exist?
					name = browser.span(id:'productTitle').text
					found=true
				else
					name = 'no title listed for product'
					found=false
				end
				worksheet.add_cell(3, 1, name)
				worksheet.add_cell(3, 2, '', "HYPERLINK(\"#{browser.url}\")")
				worksheet[3][1].change_fill('FF0000') unless found
				worksheet.add_cell(4, 0, "Product Features")
				if browser.div(id:'feature-bullets').exist?
					features =browser.div(id:'feature-bullets').text
					found = true
				else
					features = 'no feature bullets listed for product'
					found=false
				end
				worksheet.add_cell(4, 1, features)
				worksheet[4][1].change_fill('FF0000') unless found
				worksheet.add_cell(5, 0, "Product Description")
				if browser.iframe(id:'product-description-iframe').div(id:'productDescription').exist?	
					desc = browser.iframe(id:'product-description-iframe').div(id:'productDescription').text.sub("Product Description\n", '')
					found = true
				else
					desc = 'no description listed for product'
					found=false
				end
				worksheet.add_cell(5, 1, desc)
				worksheet[5][1].change_fill('FF0000') unless found
				worksheet.add_cell(6, 0, "Product Details")
				if browser.div(id:'detail-bullets_feature_div').exist?
					details = browser.div(id:'detail-bullets_feature_div').text.sub("Product Details\n", '').sub(browser.div(id:'detail-bullets_feature_div').div(class:'bucket').text, '')
					found = true
				else
					details = 'no details listed for product'
					found=false
				end
				worksheet.add_cell(6, 1, details)
				worksheet[6][1].change_fill('FF0000') unless found
			end

			# save the workbook
			worksheet.change_column_width(0, 25) 
			worksheet.change_column_width(1, 50) 
			worksheet.change_column_width(2, 50) 
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
		system("start #{File.absolute_path(workbook_location)}")
	end
end
