@error = false
begin
	asins_imported = ARGV[0]
	batch_number = ARGV[1].nil? ? 1.to_s : ARGV[1].to_s
	puts "Beginning Amazon Search"
	@temp_folder = @root_folder + "/temp/amazon_#{tstamp}"
	FileUtils.mkdir_p(@temp_folder)
	puts "Temp folder location: #{File.absolute_path(@temp_folder)}"
	dots

	workbook_location = "#{@temp_folder}/AMAZON_DATA_#{@run_stamp}_batch#{batch_number}.xlsx"
	puts "\nCreating results workbook at #{workbook_location}"
	result_urls = []
	result_counts = []
	workbook = RubyXL::Workbook.new
	workbook[0].sheet_name = 'Summary'
	workbook[0].change_column_width(0, 50)
	asins = RubyXL::Parser.parse(@amazon_data).first.extract_data
	asins.delete_if { |a| a.to_s == "[nil, nil, nil, nil]" }
	asins.each_with_index do |asin, i|
		workbook[0].add_cell(i, 0, asin[0])
		workbook[0].add_cell(i, 1, asin[1])
		workbook[0].add_cell(i, 2, asin[2])
		workbook[0].add_cell(i, 3, asin[3])
	end
	workbook.write(workbook_location)

	puts "\nCreating browser instance"
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
	asins[1..-1].each_with_index do |item, i|
		puts "\nApplication runtime: #{seconds_to_string(Time.now - @start_time)}"

		#search for the current product
		model, upc, desc, asin = item
		case 
		when !asin.nil?
			product = asin
		when !upc.nil?
			product = upc
		when !model.nil?
			product = model
		when !desc.nil?
			product = desc
		else
			puts "Can't search when all info is nil!"	
			puts item
			pushbullet_note_to_all("Encountered nil item in automation!", "Item ##{i} is nil!\n#{item.to_s}")
			next
		end
		puts "\nprocessing product [#{product} | #{desc}] - #{i + 1} of #{asins.count - 1}"
		worksheet = workbook.add_worksheet(product)
		worksheet.add_cell(0, 0, product)
		worksheet.add_cell(0, 1, desc)
		searchbox.set product
		send_enter
		puts "\nSearching for product"
		sleep 1
		browser.div(id:'navFooter').wait_until_present
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

		if no_results
			puts "\nNo results found"
		else
			# go to the first result
			puts "\nSelecting first result"
			browser.li(id:'result_0').links.first.click
			sleep 1
			browser.div(id:'navFooter').wait_until_present

			# record the name, price, features, desc, details
			# Name
			puts "\nGetting name"
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
			puts "\nGetting price"
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
			puts "\nGetting features"
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
			puts "\nGetting description"
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
			puts "\nGetting details"
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
			puts "\nGetting reviews"
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
			# puts "\nGetting questions"
			# worksheet.add_cell(8, 0, "Product Questions")
			# if browser.div(class:'askQuestionExamples').exist?
			# 	worksheet.add_cell(8, 1, "No questions exist for this product")
			# 	worksheet[8][1].change_fill('FF6161')
			# else
			# 	num_questions = browser.a(class:'askSeeMoreQuestionsLink').text.split('(').last.chop

		end

		# save the workbook
		puts "\nSaving workbook after collecting data"
		worksheet.change_column_width(0, 25)
		worksheet.change_column_width(1, 50)
		worksheet.change_column_width(2, 50)
		workbook.write(workbook_location)
	end
	# no_dots
	# puts "\n==============="
	# result_counts.each { |r| puts r }
	puts "\n===============\n"
	puts "\nFinished processing"
	puts "\nCopying workbook to results folder"
	FileUtils.copy_file(workbook_location, @results_folder + File.basename(workbook_location))
rescue Exception => e
	@error = true
	no_dots
	unless @browser.nil?
		puts "URL of browser at error:"
		puts @browser.url
		error_file = take_screenshot('ERROR')
		puts "Screenshot saved as [#{error_file}]"
		pushbullet_file_to_all("Screenshot of Automation Error", error_file, '')
		error_report(e, @browser.url)
	else	
		error_report(e)
	end
	puts "Exiting after fail due to error."
	binding.pry
end
puts "\nClosing browser"
browser.close
headless.destroy if @headless
no_dots
unless @error
	puts "Amazon scrape completed succesfully."
end
