require_relative "../libraries/main.rb"
require_relative "../libraries/amazon.rb"
require 'pry'
require 'rubyXL'
require 'awesome_print'

puts "reading data"
data = read_amazon_data
puts "ready for testing"
binding.pry
puts "exiting..."
