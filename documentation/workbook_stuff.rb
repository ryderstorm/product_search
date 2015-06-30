 puts log logfile, "Temp folder location: #{File.absolute_path(temp_folder)}"
 dots

workbook_location = "#{temp_folder}/AMAZON_DATA_#{@run_stamp}_batch#{batch_number}.xlsx"
log logfile, "Creating results workbook at #{workbook_location}"
workbook = RubyXL::Workbook.new
workbook[0].sheet_name = 'Summary'
workbook[0].change_column_width(0, 50)
asins.each_with_index do |asin, i|
	row = i
	workbook[0].add_cell(row, 0, asin[0])
	workbook[0].add_cell(row, 1, asin[1])
	workbook[0].add_cell(row, 2, asin[2])
	workbook[0].add_cell(row, 3, asin[3])
end
workbook.write(workbook_location)



worksheet = workbook.add_worksheet(product)
worksheet.add_cell(0, 0, product)
worksheet.add_cell(0, 1, desc)


worksheet.add_cell(1, 0, "Search results URL")
worksheet.add_cell(1, 1, '', "HYPERLINK(\"#{browser.url}\")")
worksheet[1][1].change_font_color('0000CC')
image = take_screenshot("#{product}_SEARCH_RESULTS")
worksheet.add_cell(1, 2, '', "HYPERLINK(\"#{image}\")")
worksheet[1][2].change_font_color('0000CC')

worksheet.add_cell(2, 2, '', "HYPERLINK(\"#{image}\")")
worksheet[2][2].change_font_color('0000CC')



worksheet.add_cell(2, 0, "Number of search results")
worksheet.add_cell(2, 1, product.num_of_results)
worksheet.add_cell(3, 1, product.name)
worksheet.add_cell(3, 2, '', "HYPERLINK(\"#{browser.url}\")")
worksheet[3][2].change_font_color('0000CC')
worksheet[3][1].change_fill('FF6161') unless found

worksheet.add_cell(0, 2, product.price)
worksheet[0][2].change_fill('FF6161') if price.to_s.length > 10

worksheet.add_cell(4, 0, "Product Features")
worksheet.add_cell(4, 1, product.features)
worksheet[4][1].change_fill('FF6161') unless found

worksheet.add_cell(5, 0, "Product Description")

worksheet.add_cell(5, 1, product.desc)
worksheet[5][1].change_fill('FF6161') unless found
worksheet.add_cell(6, 0, "Product Details")
worksheet.add_cell(6, 1, product.details)
worksheet[6][1].change_fill('FF6161') unless found

worksheet.add_cell(7, 0, "Product Reviews")
worksheet.add_cell(7, 1, "No reviews exist for this product")
worksheet[7][1].change_fill('FF6161')						

worksheet.add_cell(7, 1, "#{product.reviews_avg} average rating")
worksheet.add_cell(7, 2, "#{product.reviews_total} total reviews")
worksheet.add_cell(7, 3, '', "HYPERLINK(\"#{product.reviews_link}\")")
worksheet[7][3].change_font_color('0000CC')
worksheet.add_cell(8, 0, "Product Questions")

	worksheet.add_cell(8, 1, "No questions exist for this product")
	worksheet[8][1].change_fill('FF6161')

save the workbook
log logfile, "Saving workbook after collecting data"
worksheet.change_column_width(0, 25)
worksheet.change_column_width(1, 50)
worksheet.change_column_width(2, 50)
workbook.write(workbook_location)

log logfile, "Copying workbook to results folder"
FileUtils.copy_file(workbook_location, @root_folder + "/results/" + File.basename(workbook_location))
workbook.write(workbook_location) rescue nil