require 'watir-webdriver'
require 'headless'
require 'pry'

puts "starting headless"
headless = Headless.new
headless.start

puts "starting watir chrome"
b = Watir::Browser.new :chrome
b.goto 'www.google.com'

puts "watir chrome should be available now and is on the page\n#{b.url}"
binding.pry
puts "closing up shop"
b.close
headless.destroy

