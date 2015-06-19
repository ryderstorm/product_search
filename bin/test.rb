require './secret/secrets.rb'
require 'pry'
require 'rubyXL'
asins = RubyXL::Parser.parse(@amazon_data_test).first.extract_data
asins.each { |asin| puts asin.to_s }
puts "finished loading"
binding.pry
puts "exiting..."
