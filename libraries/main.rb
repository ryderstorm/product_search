def init_variables
	@start_time = Time.now
	@run_stamp = tstamp
	@results_folder = @root_folder + "/results/"
	@group_size = 10
	@success = true
	@cores = Facter.value('processors')['count']
	@computer = Socket.gethostname
	# @amazon_data = @computer.include?('digital-ocean') ? File.absolute_path('data/amazon.xlsx') : File.absolute_path('data/amazon_test.xlsx')
	@amazon_data = File.absolute_path('data/amazon.xlsx')
	@headless = true
	@headless = true if @computer == 'ryderstorm-amazon_search-1580844'
	@headless = true if @computer.include?('testing-worker-linux-docker')
	@headless = true if @computer.include?('digital-ocean')
	@secrets = parse_secrets(File.absolute_path('secret/secret.txt'))
end

def free_core
	return false if @cores == 1
	@cores > Thread.list.count - 1
end

def read_amazon_data(group_size = 25)
	asins = RubyXL::Parser.parse(@amazon_data).first.extract_data
	asins.delete_if { |a| a.to_s == "[nil, nil, nil, nil]" }
	asins.delete_at(0)
	groups = []
	while asins.count > 0
		groups.push asins.slice!(0, group_size.to_i)
	end
	groups
end

def tstamp
	Time.now.strftime("%Y%m%d%H%M%S").to_s
end

def dots
	@dots = Thread.new {loop {print ".";sleep 0.3333}}
	@dots
end

def no_dots
	unless @dots.nil?
		Thread.kill(@dots)
		puts ""
	end
end

def take_screenshot(filename = 'screenshot')
	return if @browser.nil?
	complete_name = "#{@temp_folder}/#{filename}_#{tstamp}.png"
	@browser.screenshot.save complete_name
	File.absolute_path(complete_name)
end

def save_image(name, src)
	extension = src.split('.').last
	complete_name = "#{@temp_folder}/#{name}_#{tstamp}.#{extension}"
	File.open(complete_name, 'wb') do |f|
		f.write open(src).read
	end
	File.absolute_path(complete_name)
end

def error_report(e, url=nil)
	message = ""
	message << "\n!!!!!!!!!!!!!!!!!!!!!\nAn error occurred!\n!!!!!!!!!!!!!!!!!!!!!\n"
	message << "\nCurrent computer: #{@computer}"
	message << "\nCurrent time: #{Time.now}"
	message << "\nTime since application start: #{seconds_to_string(Time.now - @start_time)}"
	message << "\nURL at time of error:\n#{url}" unless url.nil?
	message << "\nError message contents:"
	message << "\n#{e.message}"
	(0..10).each { |i| message << "\n\t" + e.backtrace[i] }
	message << "\n\n!!!!!!!!!!!!!!!!!!!!!\n"
	puts message
	if url.nil?
		pushbullet_note_to_all("An error has occurred in the automation!", message)
	else
		pushbullet_link_to_all("An error has occurred in the automation!", url, message)
	end
end

def pluralize(number)
	number == 1 ? (return ""):(return "s")
end

def seconds_to_string(s)
	# d = days, h = hours, m = minutes, s = seconds
	m = (s / 60).floor
	s = (s % 60).floor
	h = (m / 60).floor
	m = m % 60
	d = (h / 24).floor
	h = h % 24

	output = "#{s} second#{pluralize(s)}" if (s > 0)
	output = "#{m} minute#{pluralize(m)}, #{s} second#{pluralize(s)}" if (m > 0)
	output = "#{h} hour#{pluralize(h)}, #{m} minute#{pluralize(m)}, #{s} second#{pluralize(s)}" if (h > 0)
	output = "#{d} day#{pluralize(d)}, #{h} hour#{pluralize(h)}, #{m} minute#{pluralize(m)}, #{s} second#{pluralize(s)}" if (d > 0)

	return output
end

def parse_secrets(secrets_location)
	secrets = {}
	info = File.read(secrets_location).split
	info.each do |i|
		secrets.store(i.split('|').first.to_sym, i.split('|').last)
	end
	secrets
end
