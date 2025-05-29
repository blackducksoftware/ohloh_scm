require 'spec_helper'

describe 'System' do
  describe 'run' do
    it 'must run a command succesfully' do
      run_p('ls /tmp')
    end

    it 'must raise an exception when command fails' do
      assert_raises(Exception) { run_p('ls /tmp/foobartest') }
    end
  end

  describe 'run_with_error' do
    it 'must provide error and exitstatus' do
      cmd = %q(ruby -e"  t = 'Hello World'; STDOUT.puts t; STDERR.puts t  ")
      stdout, stderr, status = run_with_error_p(cmd)
      assert_equal status.exitstatus, 0
      assert_equal stdout, "Hello World\n"
      assert_equal stderr, "Hello World\n"
    end
  end

  describe 'logger' do
    it 'must allow setting logger level' do
      level = (1..5).to_a.sample
      OhlohScm::System.logger.level = level
      core = OhlohScm::Factory.get_core(scm_type: :git, url: 'foo')
      assert_equal core.scm.send(:logger).level, level
    end
  end
end
