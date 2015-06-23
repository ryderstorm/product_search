require_relative '../libraries/main.rb'
require_relative '../libraries/pushbullet.rb'

Dir.glob(File.join("**", "AMAZON_DATA*.xlsx")).each do |file|
	pushbullet_file_to_all("Pushing all excel files", File.absolute_path(file), '')
end

