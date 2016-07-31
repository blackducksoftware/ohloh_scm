require 'rubygems'
require 'stringio'
require 'posix/spawn'

class Shellout

  def self.relay src, dst
    while((buf = src.read(8192))); dst << buf; end 
  end 

  def self.execute(cmd)
    posix_spawn = POSIX::Spawn::Child.new(cmd)

    return posix_spawn.status, posix_spawn.out, posix_spawn.err
  end

  def run(cmd)
    Shellout::execute(cmd)
  end

end

if $0 == __FILE__
  shell = Shellout.new
  date = %q( ruby -e"  t = Time.now; STDOUT.puts t; STDERR.puts t  " )
  status, stdout, stderr = shell.run(date)
  p [status.exitstatus, stdout, stderr]

  sleep = %q( ruby -e"  p(sleep(1))  " )
  status, stdout, stderr = shell.run(sleep)
  p [status.exitstatus, stdout, stderr]

  cat = 'ruby -e"  puts Array.new(65536){ 42 }  "'
  status, stdout, stderr = shell.run(cat)
  p [status.exitstatus, stdout, stderr]

  status, stdout, stderr = shell.run('osiudfoisynajtet32')
  p [status.exitstatus, stdout, stderr]

end


