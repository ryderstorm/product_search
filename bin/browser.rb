require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require 'pry'
require 'awesome_print'
require_relative '../libraries/main.rb'
begin 
	start = Time.now
	puts "Loading browser"
	dots
	url = 'http://www.amazon.com'
	# headless = Headless.new
	# headless.start
	browser = Watir::Browser.new :chrome
	@browser = browser
	searchbox = browser.text_field(id:'twotabsearchtextbox')
	# browser.window.resize_to(900, 1000)
	# browser.window.move_to(0, 0)
	binding.pry
	searching = Thread.new do
		loop do
			puts "Searchbox present? #{searchbox.present?}"
			sleep 0.25
		end
	end
	sleep 1
	browser.goto url
	browser.div(id:'navFooter').wait_until_present
	loaded_image = "./temp/browser_loaded_#{tstamp}.png"
	browser.screenshot.save loaded_image
	no_dots

	puts "Browser finished loading website [#{url}] in #{(Time.now - start).round(2)} seconds"
	binding.pry


	puts "Finished testing"
rescue Exception => e
	puts e.message
	puts e.backtrace
	"Starting pry session after error..."	
	binding.pry
ensure
	puts "Clearing resources"
	dots
	browser.close
	headless.destroy unless headless.nil?
	File.delete(loaded_image)
	Thread.list.each{|t| puts "#{Time.now} | Closing thread #{t}";t.join}
	no_dots
	puts "Resources cleared - exiting"
end