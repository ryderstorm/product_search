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

def ssh_rake(ip)
  output = ''
  Net::SSH.start(ip, 'root', :paranoid => false) do |ssh|
    # output = ssh.exec!('cd amazon_search/ && git checkout master && git pull && rake local')
    output = ssh.exec!('cd amazon_search/ && git checkout adding_netssh && git pull && rake local')
  end
  output
end