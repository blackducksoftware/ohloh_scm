# Usage: ruby process_spawn_benchmark.rb [-n <count>] [-m <mem-size>]
# Run posix-spawn (Ruby extension) benchmarks and report to standard output.
#
# Options:
#   -n, --count=NUM         total number of processes to spawn.
#   -m, --mem-size=MB       RES size to bloat to before performing benchmarks.
#
# Benchmarks run with -n 500 -m 100 by default.
require 'optparse'
require 'posix-spawn'
require 'benchmark'
require 'digest/sha1'
require 'open3'

class ProcessSpawnBenchmark
  include Benchmark

  def initialize(allocate, iterations)
    bloat_main_process_memory(allocate)
    repo_path = setup_test_repository
    @cmd = "cd #{repo_path} && git log"
    @iterations = iterations
    benchmark_all
  end

  private

  def bloat_main_process_memory(allocate)
    _ = 'x' * allocate
    memory_used = `ps aux | grep #{File.basename(__FILE__)} | grep -v grep | awk '{print $6/1000}'`.strip.to_i
    puts "Parent process: #{memory_used}MB RESidual memory"
  end

  def setup_test_repository
    repo_name = 'git'
    repo_path = File.expand_path("../scm_fixtures/#{repo_name}.tgz", __dir__)
    dest_path = "/tmp/#{repo_name}"
    system("rm -rf #{dest_path} && tar xvf #{repo_path} -C /tmp/ > /dev/null")
    dest_path
  end

  def benchmark_all
    puts "Benchmarking: #{@iterations} child processes spawned for each"
    bmbm 40 do |reporter|
      @reporter = reporter
      benchmark_open3
      benchmark_posix_spawn_child
      benchmark_posix_spawn
      benchmark_popen
      benchmark_system
      benchmark_spawn if Process.respond_to?(:spawn)
      benchmark_fork_exec
    end
  end

  def benchmark_open3
    @reporter.report('Open3.capture3 => ') do
      @iterations.times do
        stdout, = Open3.capture3(@cmd)
        verify_output(stdout, __method__)
      end
    end
  end

  def benchmark_posix_spawn_child
    @reporter.report('POSIX::Spawn::Child => ') do
      @iterations.times do
        child = POSIX::Spawn::Child.new(@cmd)
        verify_output(child.out, __method__)
      end
    end
  end

  def benchmark_posix_spawn
    @reporter.report('pspawn (posix_spawn) => ') do
      @iterations.times do
        pid = POSIX::Spawn.pspawn("#{@cmd} > /dev/null")
        Process.wait(pid)
      end
    end
  end

  def benchmark_popen
    @reporter.report('IO.popen:') do
      @iterations.times do
        IO.popen(@cmd).each { |_line| } # consume output to avoid Lint/EmptyBlock
      end
    end
  end

  def benchmark_system
    @reporter.report('``:') do
      @iterations.times do
        stdout = `#{@cmd}`
        verify_output(stdout, __method__)
      end
    end
  end

  def benchmark_spawn
    @reporter.report('spawn (native):') do
      @iterations.times do
        pid = Process.spawn("#{@cmd} > /dev/null")
        Process.wait(pid)
      end
    end
  end

  def benchmark_fork_exec
    @reporter.report('fspawn (fork/exec):') do
      @iterations.times do
        pid = POSIX::Spawn.fspawn("#{@cmd} > /dev/null")
        Process.wait(pid)
      end
    end
  end

  def verify_output(stdout, method_name)
    return if Digest::SHA1.hexdigest(stdout) == 'df31df68785baa8725e40e2a2583bb8f7e9dd3c5'

    raise "Git log output did not match for #{method_name.slice(/benchmark_(.+)$/, 1)}"
  end
end

allocate   = 100 * (1024**2)
iterations = 500
ARGV.options do |o|
  o.on('-n', '--count=num')   { |val| iterations = val.to_i }
  o.on('-m', '--mem-size=MB') { |val| allocate   = val.to_i * (1024**2) }
  o.parse!
end

ProcessSpawnBenchmark.new(allocate, iterations)
