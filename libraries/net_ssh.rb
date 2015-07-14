require 'net/ssh'
require 'colorize'
def ssh_shutdown(ip)
  command = 'shutdown now -h'
  puts "Sending the following command to [#{ip.yellow}]: \n" + command.yellow
  Net::SSH.start(ip, 'root', :paranoid => false) do |ssh|
    ssh.exec!(command) rescue nil
  end
  rescue => e
  puts report_error(e, "Error encountered during ssh_shutdown")
end

def ssh_command(ip, command)
  output = ''
  puts "Sending the following command to [#{ip.yellow}]: \n" + command.yellow
  Net::SSH.start(ip, 'root', :paranoid => false) do |ssh|
    output = ssh.exec!(command)
  end
  output
  rescue => e
  puts report_error(e, "Error encountered during ssh_command")
end

def ssh_rake(ip, data_set = 'all')
  output = ''
  command = "cd ~/amazon_search/ && git pull && git checkout adding_netssh && git pull && bundle install && rake data_set_#{data_set} local"
  puts "Sending the following command to [#{ip.yellow}]: \n" + command.yellow
  Net::SSH.start(ip, 'root', :paranoid => false) do |ssh|
    output = ssh.exec!(command)
  end
  output
  rescue => e
  puts report_error(e, "Error encountered during ssh_rake")
end
