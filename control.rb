require './lib.rb'
@start_time = Time.now
amazon_search
puts "\n===============\nTotal processing time: #{seconds_to_string(Time.now - @start_time)}" 
puts "\nThe application is finished. Press enter to exit."
gets.chomp
exit
