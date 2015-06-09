require 'watir-webdriver'
require 'headless'
require 'rubyXL'
require 'pry'
require './amazon_search.rb'
require './lib.rb'

start = Time.now
puts "Loading browser"
dots
url = 'http://www.amazon.com'
headless = Headless.new
headless.start
browser = Watir::Browser.new
@browser = browser
browser.goto url
browser.div(id:'navFooter').wait_until_present
loaded_image = "./temp/browser_loaded_#{tstamp}.png"
browser.screenshot.save loaded_image
no_dots

puts "Browser finished loading website [#{url}] in #{Time.now - start} seconds"
binding.pry
puts "Clearing resources"
dots
browser.close
headless.destroy
File.delete(loaded_image)
no_dots
puts "Resources cleared - exiting"
