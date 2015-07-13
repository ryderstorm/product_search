require 'net/ssh'
def ssh_shutdown(ip)
  command = 'shutdown now -h'
  Net::SSH.start(ip, 'root', :paranoid => false) do |ssh|
    ssh.exec!(command) rescue nil
  end
end

def ssh_command(ip, command)
  output = ''
  Net::SSH.start(ip, 'root', :paranoid => false) do |ssh|
    output = ssh.exec!(command)
  end
  output
end

def ssh_rake(ip, data_set = 'all')
  output = ''
  command = "cd amazon_search/ && git checkout adding_netssh && git pull && data_set_#{data_set} && rake local"
  Net::SSH.start(ip, 'root', :paranoid => false) do |ssh|
    output = ssh.exec!(command)
  end
  output
end