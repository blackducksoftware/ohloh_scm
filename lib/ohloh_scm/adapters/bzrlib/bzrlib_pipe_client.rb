require 'rubygems'
require 'posix/spawn'

class BzrPipeClient
  def initialize(repository_url)
    @repository_url = repository_url
    @py_script = File.dirname(__FILE__) + '/bzrlib_pipe_server.py'
  end

  def start
    @pid, @stdin, @stdout, @stderr = POSIX::Spawn::popen4 "python #{@py_script}"
    open_repository
  end

  def open_repository
    send_command("REPO_OPEN|#{@repository_url}")
  end
  def cat_file(revision, file)
    send_command("CAT_FILE|#{revision}|#{file}")
  end

  def parent_tokens(revision)
    send_command("PARENT_TOKENS|#{revision}").split('|')
  end

  def send_command(cmd)
    # send the command
    @stdin.puts cmd
    @stdin.flush
    return if cmd == "QUIT"

    # get status on stderr, first letter indicates state,
    # remaing value indicates length of the file content
    status = @stderr.read(10)
    flag = status[0,1]
    size = status[1,9].to_i
    if flag == 'F'
      return nil
    elsif flag == 'E'
      error = @stdout.read(size)
      raise RuntimeError.new("Exception in server process\n#{error}")
    end

    # read content from stdout
    return @stdout.read(size)
  end

  def shutdown
    send_command("QUIT")
    [@stdout, @stdin, @stderr].each { |io| io.close unless io.closed? }
    Process.waitpid(@pid, Process::WNOHANG)
  end
end

def cat_all_files(client, datafile)
  count = 0
  bytes = 0
  File.open(datafile).each do |line|
    parts = line.split('|')
    count = count + 1
    bytes = bytes + client.cat_file(parts[0], parts[1]).size
    puts "file=#{count}, bytes=#{bytes}"
  end
end

def all_parent_tokens(client, datafile)
  File.open(datafile).each do |line|
    parts = line.split('|')
    puts client.parent_tokens(parts[0])
  end
end
