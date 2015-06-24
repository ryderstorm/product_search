require 'washbullet'

def pb_client
	api_key = @secrets[:pushbullet_api_key]
	# @damien_galaxy_s3 = @secrets[:damien_galaxy_s3]
	client = Washbullet::Client.new(api_key)
end

def pushbullet_note_to_all(title, message)
  pb_client.push_note(receiver:nil, identifier: '<IDENTIFIER>', params:{title: title, body: message})
end

def pushbullet_file_to_all(title, file, message)
  # @client.push_file(@all_devices, title, file, message)
  pb_client.push_file(receiver:nil, identifier: '<IDENTIFIER>', params:{file_name: title, file_path: file, body: message})
end

def pushbullet_link_to_all(title, link, message)
  pb_client.push_link(receiver:nil, identifier: '<IDENTIFIER>', params:{title: title, url: link, body: message})
end
