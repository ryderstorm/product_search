def amazon_search(browser, asins, batch_number = 1)
	error = false
	temp_folder = @root_folder + "/temp/amazon_#{@run_stamp}"
	Dir.mkdir(temp_folder) unless Dir.exist?(temp_folder)
	logfile = temp_folder + "/amazon_runlog_#{@run_stamp}_#{batch_number}.txt"
	FileUtils.mkdir_p(temp_folder)
	puts log logfile, "Temp folder location: #{File.absolute_path(temp_folder)}"
	# dots

	workbook_location = "#{temp_folder}/AMAZON_DATA_#{@run_stamp}_batch#{batch_number}.xlsx"
	log logfile, "Creating results workbook at #{workbook_location}"
	result_urls = []
	result_counts = []
	workbook = RubyXL::Workbook.new
	workbook[0].sheet_name = 'Summary'
	workbook[0].change_column_width(0, 50)
	asins.each_with_index do |asin, i|
		row = i + 1
		workbook[0].add_cell(row, 0, asin[0])
		workbook[0].add_cell(row, 1, asin[1])
		workbook[0].add_cell(row, 2, asin[2])
		workbook[0].add_cell(row, 3, asin[3])
	end
	workbook.write(workbook_location)

	unless @headless
		browser.window.resize_to(900, 1000)
		browser.window.move_to(0, 0)
	end
	browser.goto 'http://www.amazon.com'
	searchbox = browser.text_field(id:'twotabsearchtextbox')
	asins.each_with_index do |item, i|
		log logfile, "Application runtime: #{seconds_to_string(Time.now - @start_time)}"

		#search for the current product
		model, upc, desc, asin = item
		case 
		when !asin.nil?
			product = asin.to_s
		when !upc.nil?
			product = upc.to_s
		when !model.nil?
			product = model.to_s
		when !desc.nil?
			product = desc.to_s
		else
			log logfile, "Can't search when all info is nil!"	
			log logfile, item
			pushbullet_note_to_all("Encountered nil item in automation!", "Item ##{i} is nil!#{item.to_s}")
			next
		end
		log logfile, "processing product [#{product} | #{desc}] - #{i + 1} of #{asins.count}"
		worksheet = workbook.add_worksheet(product)
		worksheet.add_cell(0, 0, product)
		worksheet.add_cell(0, 1, desc)
		searchbox.set product
		browser.send_keys :enter
		log logfile, "Searching for product: [#{product}]"
		sleep 1
		worksheet.add_cell(1, 0, "Search results URL")
		worksheet.add_cell(1, 1, '', "HYPERLINK(\"#{browser.url}\")")
		worksheet[1][1].change_font_color('0000CC')
		image = take_screenshot("#{product}_SEARCH_RESULTS")
		worksheet.add_cell(1, 2, '', "HYPERLINK(\"#{image}\")")
		worksheet[1][2].change_font_color('0000CC')
		case 
		when browser.h1(id:'noResultsTitle').present?
			# move on if no results were found
			result_counts.push "#{i+1}. | #{product.center(20)} | #{desc} | NO results FOUND"
			no_results = true
			number_results = 0
		when browser.element(id:'noresult_countsTitle').present?
			# move on if no results were found
			result_counts.push "#{i+1}. | #{product.center(20)} | #{desc} | NO results FOUND"
			no_results = true
			number_results = 0
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
			# image = save_image("#{product}_SEARCH_THUMBNAIL", browser.li(id:'result_0').imgs.first.attribute_value('src'))
			image = browser.li(id:'result_0').imgs.first.attribute_value('src')
			worksheet.add_cell(2, 2, '', "HYPERLINK(\"#{image}\")")
			worksheet[2][2].change_font_color('0000CC')
		end
		worksheet.add_cell(2, 0, "Number of search results")
		worksheet.add_cell(2, 1, number_results)

		browser.div(id:'navFooter').wait_until_present
		if no_results
			log logfile, "No results found"
		else
			# go to the first result
			log logfile, "Selecting first result"
			browser.li(id:'result_0').links.first.click
			sleep 1
			browser.div(id:'navFooter').wait_until_present

			# record the name, price, features, desc, details
			# Name
			log logfile, "Getting name"
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
			worksheet[3][2].change_font_color('0000CC')
			worksheet[3][1].change_fill('FF6161') unless found

			# Price
			log logfile, "Getting price"
			case
			when browser.span(id:'priceblock_ourprice').present?
				price = browser.span(id:'priceblock_ourprice').text
			when browser.a(text:'See price in cart').present?
				browser.a(text:'See price in cart').click
				browser.span(id:'priceblock_ourprice').wait_until_present
				price = browser.span(id:'priceblock_ourprice').text
				browser.button(data_action:'a-popover-close').wait_until_present
				browser.button(data_action:'a-popover-close').click
			when browser.div(id:'olp_feature_div').present?
				price = browser.div(id:'olp_feature_div').text.split('from ').last
			else
				price = "No price found on page, see url for details"
			end
			worksheet.add_cell(0, 2, price)
			worksheet[0][2].change_fill('FF6161') if price.length > 10

			# Features
			log logfile, "Getting features"
			worksheet.add_cell(4, 0, "Product Features")
			if browser.div(id:'feature-bullets').exist?
				features =browser.div(id:'feature-bullets').text
				found = true
			else
				features = 'no feature bullets listed for product'
				found = false
			end
			worksheet.add_cell(4, 1, features)
			worksheet[4][1].change_fill('FF6161') unless found

			# Description
			log logfile, "Getting description"
			worksheet.add_cell(5, 0, "Product Description")
			if browser.iframe(id:'product-description-iframe').div(id:'productDescription').exist?
				desc = browser.iframe(id:'product-description-iframe').div(id:'productDescription').text.sub("Product Description\n", '')
				found = true
			else
				desc = 'no description listed for product'
				found=false
			end
			worksheet.add_cell(5, 1, desc)
			worksheet[5][1].change_fill('FF6161') unless found

			# Details
			log logfile, "Getting details"
			worksheet.add_cell(6, 0, "Product Details")
			if browser.div(id:'detail-bullets_feature_div').exist?
				details = browser.div(id:'detail-bullets_feature_div').text.sub("Product Details\n", '').sub(browser.div(id:'detail-bullets_feature_div').div(class:'bucket').text, '')
				found = true
			else
				details = 'no details listed for product'
				found=false
			end
			worksheet.add_cell(6, 1, details)
			worksheet[6][1].change_fill('FF6161') unless found

			# Reviews
			log logfile, "Getting reviews"
			worksheet.add_cell(7, 0, "Product Reviews")
			if browser.div(id:'averageCustomerReviews_feature_div').text == 'Be the first to review this item'
				worksheet.add_cell(7, 1, "No reviews exist for this product")
				worksheet[7][1].change_fill('FF6161')
			else
				review_avg = browser.div(id:'averageCustomerReviews').span(id:'acrPopover').title.split.first
				review_total = browser.span(id:'acrCustomerReviewText').text.split.first
				# review_link = browser.a(id:'acrCustomerReviewLink').href # link to reviews section of product page
				review_link = browser.div(id:'revF').as.first.href # link to all reviews on separate page
				worksheet.add_cell(7, 1, "#{review_avg} average rating")
				worksheet.add_cell(7, 2, "#{review_total} total reviews")
				worksheet.add_cell(7, 3, '', "HYPERLINK(\"#{review_link}\")")
				worksheet[7][3].change_font_color('0000CC')
			end

			# Questions & answers
			# log logfile, "Getting questions"
			# worksheet.add_cell(8, 0, "Product Questions")
			# if browser.div(class:'askQuestionExamples').exist?
			# 	worksheet.add_cell(8, 1, "No questions exist for this product")
			# 	worksheet[8][1].change_fill('FF6161')
			# else
			# 	num_questions = browser.a(class:'askSeeMoreQuestionsLink').text.split('(').last.chop
		end

		# save the workbook
		log logfile, "Saving workbook after collecting data"
		worksheet.change_column_width(0, 25)
		worksheet.change_column_width(1, 50)
		worksheet.change_column_width(2, 50)
		workbook.write(workbook_location)
	end
	# no_dots
	# log logfile, "==============="
	# result_counts.each { |r| log logfile, r }
	log logfile, "==============="
	log logfile, "Finished processing"
	log logfile, "Copying workbook to results folder"
	FileUtils.copy_file(workbook_location, @results_folder + File.basename(workbook_location))
rescue Exception => e
	error = true
	no_dots
	browser_exist = browser.nil? rescue false
	if browser_exist
		log logfile, "URL of browser at error:"
		log logfile, browser.url
		error_file = take_screenshot('ERROR')
		log logfile, "Screenshot saved as [#{error_file}]"
		pushbullet_file_to_all("Screenshot of Automation Error", error_file, '')
		log logfile, error_report(e, browser.url)
	else
		log logfile, "Browser did not exist at time of error"
		log logfile, error_report(e)
	end
	log logfile, "Exiting after fail due to error."
	# binding.pry
rescue Interrupt
	log logfile, "User pressed Ctrl+C"
ensure
	# binding.pry
	log logfile, "Closing resources"
	#browser.close rescue nil
	workbook.write(workbook_location) rescue nil
	log logfile, "Workbook located at:#{workbook_location}"
	# headless.destroy if @headless
	no_dots
	@success = !error
	pushbullet_note_to_all("Amazon search #{@run_stamp}-#{batch_number}: #{!error}", File.read(temp_folder + "/amazon_runlog_#{@run_stamp}_#{batch_number}.txt"))
	return !error
end
