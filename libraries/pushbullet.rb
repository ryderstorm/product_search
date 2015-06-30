require 'washbullet'

def pb_client
	api_key = @secrets[:pushbullet_api_key]
	@damien_galaxy_s3 = @secrets[:damien_galaxy_s3]
	@chrome = @secrets[:chrome]
	client = Washbullet::Client.new(api_key)
end

def pushbullet_note_to_all(title, message,  receivers=nil)
  pb_client.push_note(receiver:receivers, identifier: '<IDENTIFIER>', params:{title: title, body: message})
end

def pushbullet_file_to_all(title, file, message,  receivers=nil)
  # @client.push_file(@all_devices, title, file, message)
  pb_client.push_file(receiver:receivers, identifier: '<IDENTIFIER>', params:{file_name: title, file_path: file, body: message})
end

def pushbullet_link_to_all(title, link, message,  receivers=nil)
  pb_client.push_link(receiver:receivers, identifier: '<IDENTIFIER>', params:{title: title, url: link, body: message})
end
