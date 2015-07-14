require 'net/ssh'
require 'colorize'
def ssh_shutdown(ip)
  command = 'shutdown now -h'
  puts "Sending the following command to [#{ip.yellow}]: \n" + command.yellow
  Net::SSH.start(ip, 'root', :paranoid => false, :timeout => 15) do |ssh|
    ssh.exec!(command) rescue nil
  end
  rescue => e
  puts report_error(e, "Error encountered during ssh_shutdown")
end

def ssh_command(ip, command)
  output = ''
  puts "Sending the following command to [#{ip.yellow}]: \n" + command.yellow
  Net::SSH.start(ip, 'root', :paranoid => false, :timeout => 15) do |ssh|
    output = ssh.exec!(command)
  end
  output
  rescue => e
  puts report_error(e, "Error encountered during ssh_command")
end

def ssh_rake(ip, data_set = 'all')
  command = "cd ~/amazon_search/ && git clean -f && git pull && git checkout master -f && git pull && bundle install && rake data_set_#{data_set} local"
  puts "Sending the following command to [#{ip.yellow}]: \n" + command.yellow
  Net::SSH.start(ip, 'root', :paranoid => false, :timeout => 15) do |ssh|
    channel = ssh.open_channel do |ch|
      ch.exec command do |ch, success|
        raise "could not execute command" unless success
        # "on_data" is called when the process writes something to stdout
        ch.on_data do |c, data|
          $stdout.print data
        end
        # "on_extended_data" is called when the process writes something to stderr
        ch.on_extended_data do |c, type, data|
          $stderr.print data
        end

        ch.on_close { puts "#{local_time} | Command execution on [#{ip.yellow}] is complete." }
      end
    end
  end
  rescue => e
  puts report_error(e, "Error encountered during ssh_rake")
end
