def amazon_search(browser, asins, batch_number = 1)
	# begin
		error = false
		temp_folder = @root_folder + "/temp/amazon_#{@run_stamp}"
		Dir.mkdir(temp_folder) unless Dir.exist?(temp_folder)
		logfile = temp_folder + "/amazon_runlog_#{@run_stamp}_#{batch_number}.txt"
		FileUtils.mkdir_p(temp_folder)

		result_urls = []
		result_counts = []

		unless @headless
			browser.window.resize_to(900, 1000)
			browser.window.move_to(0, 0)
		end
		product = 'product not yet defined'
		search_start = ''

		asins.each_with_index do |item, i|
			begin
				Timeout::timeout(30) do
					search_start = Time.now
					log logfile, "Application runtime: #{seconds_to_string(Time.now - @start_time)}"
					product = Product.new(item)
					searchbox = browser.text_field(id:'twotabsearchtextbox')
					browser.goto 'http://www.amazon.com' unless searchbox.present?
					
					#search for the current product
					product.model, product.upc, product.name, product.asin = item
					case
					when !product.asin.nil?
						product.search_term = product.asin.to_s
					when !product.upc.nil?
						product.search_term = product.upc.to_s
					when !product.model.nil?
						product.search_term = product.model.to_s
					when !product.name.nil?
						product.search_term = product.name.to_s
					else
						log logfile, "Can't search when all info is nil!"	
						log logfile, item
						pushbullet_note_to_all("Encountered nil item in automation!", "Item ##{i} is nil!#{item.to_s}", @chrome)
						next
					end
					log logfile, "processing product [#{product.search_term} | #{product.name}] - #{i + 1} of #{asins.count}"
					searchbox.set product.search_term
					browser.send_keys :enter
					log logfile, "Searching for product: [#{product.search_term}]"
					sleep 1
					# image = take_screenshot("#{product.search_term}_SEARCH_RESULTS")

					# Results
					case 
					when browser.h1(id:'noResultsTitle').present?
						# move on if no results were found
						result_counts.push "#{i+1}. | #{product.search_term.center(20)} | #{product.name} | NO results FOUND"
						no_results = true
						product.number_of_results = 0
					when browser.element(id:'noresult_countsTitle').present?
						# move on if no results were found
						result_counts.push "#{i+1}. | #{product.search_term.center(20)} | #{product.name} | NO results FOUND"
						no_results = true
						product.number_of_results = 0
					else
						# get the number of results
						no_results = false
						search_result_counts = browser.element(id:'s-result-count').text
						if search_result_counts.include?('1 result')
								product.number_of_results = 1
						elsif search_result_counts.include?(' of ')
							product.number_of_results = search_result_counts.split('of ').last.split(' results').first
						else
							product.number_of_results = search_result_counts.split(' ').first
						end
						# image = save_image("#{product}_SEARCH_THUMBNAIL", browser.li(id:'result_0').imgs.first.attribute_value('src'))
						# image = browser.li(id:'result_0').imgs.first.attribute_value('src')
					end

					browser.div(id:'navFooter').wait_until_present
					product.search_link = browser.url
					if no_results
						log logfile, "No results found"
					else
						# go to the first result
						log logfile, "Selecting first result"
						browser.li(id:'result_0').links.first.click
						sleep 1
						browser.div(id:'navFooter').wait_until_present
						product.item_link = browser.url
						# record the Title, price, features, desc, details
						# Title
						log logfile, "Getting name"
						if browser.span(id:'productTitle').exist?
							product.title = browser.span(id:'productTitle').text
						else
							product.title = 'no title listed for product'
						end

						# Price
						log logfile, "Getting price"
						case
						when browser.span(id:'priceblock_ourprice').present?
							product.price = browser.span(id:'priceblock_ourprice').text
						when browser.a(text:'See price in cart').present?
							browser.a(text:'See price in cart').click
							browser.span(id:'priceblock_ourprice').wait_until_present
							product.price = browser.span(id:'priceblock_ourprice').text
							browser.button(data_action:'a-popover-close').wait_until_present
							browser.button(data_action:'a-popover-close').click
						when browser.div(id:'olp_feature_div').present?
							product.price = browser.div(id:'olp_feature_div').text.split('from ').last
						else
							product.price = "No price found on page, see url for details"
						end

						# Features
						log logfile, "Getting features"
						if browser.div(id:'feature-bullets').exist?
							product.features =browser.div(id:'feature-bullets').text
						else
							product.features = 'no feature bullets listed for product'
						end

						# Description
						log logfile, "Getting description"
						if browser.iframe(id:'product-description-iframe').div(id:'productDescription').exist?
							product.description = browser.iframe(id:'product-description-iframe').div(id:'productDescription').text.sub("Product Description\n", '')
						else
							product.description = 'no description listed for product'
						end

						# Details
						log logfile, "Getting details"
						if browser.div(id:'detail-bullets_feature_div').exist?
							product.details = browser.div(id:'detail-bullets_feature_div').text.sub("Product Details\n", '').sub(browser.div(id:'detail-bullets_feature_div').div(class:'bucket').text, '')
						else
							product.details = 'no details listed for product'
						end

						# Reviews
						log logfile, "Getting reviews"
						if browser.div(id:'averageCustomerReviews_feature_div').text == 'Be the first to review this item'
							product.reviews_average = "n/a"
							product.reviews_total = "0"
							product.reviews_link = "There are no reviews for this product yet"
						else
							product.reviews_average = browser.div(id:'averageCustomerReviews').span(id:'acrPopover').title.split.first
							product.reviews_total = browser.span(id:'acrCustomerReviewText').text.split.first
							# review_link = browser.a(id:'acrCustomerReviewLink').href # link to reviews section of product page
							product.reviews_link = browser.div(id:'revF').as.first.href # link to all reviews on separate page
						end

						# Questions & answers
						# log logfile, "Getting questions"
						# if browser.div(class:'askQuestionExamples').exist?
						# else
						# 	num_questions = browser.a(class:'askSeeMoreQuestionsLink').text.split('(').last.chop
					end

					log logfile, "==============="
					log logfile, "Finished processing"
				end
			rescue Timeout::Error => msg
				log logfile, "#{Time.now} | Recovered from Timeout #{seconds_to_string(Time.now - search_start)} into search for [#{product.search_term}]"
			ensure
				log logfile, "#{Time.now} | Pushing product #{product.model} to @amazon_products"
				@amazon_products.push product
				log logfile, product.all_info
				File.write(@product_log, "#{@amazon_products.count}|#{@amazon_product_count}")
			end
		end
	rescue => e
		@error = true
		# no_dots
		report = error_report(e)
		puts log logfile, report
		# pushbullet_note_to_all("Error occurred in automation!", report, @chrome)
		browser_exist = !browser.nil? rescue false
		if browser_exist
			log logfile, "URL of browser at error:"
			log logfile, browser.url
			error_file = take_screenshot('ERROR')
			log logfile, "Screenshot saved as [#{error_file}]"
			pushbullet_file_to_all("Screenshot of Automation Error", error_file, report, @chrome)
			log logfile, error_report(e, browser.url)
		end
		log logfile, "Exiting after fail due to error."
		# binding.pry
	rescue Interrupt
		log logfile, "User pressed Ctrl+C"
		# binding.pry
	ensure
		log logfile, "Closing resources"
		#browser.close rescue nil
		# headless.destroy if @headless
		# no_dots
		log logfile, "Amazon search #{batch_number} ended in status: #{!@error}"

		return [!@error, product]
	# end
end
