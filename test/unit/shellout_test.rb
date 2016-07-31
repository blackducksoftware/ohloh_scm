require_relative '../test_helper'
require 'timeout'

class ShelloutTest < OhlohScm::Test
  def test_execute_must_pipe_the_results_accurately
    status, out, err = Shellout.execute("ruby -e 'puts %[hello world]; STDERR.puts(%[some error])'")

    assert_equal out, "hello world\n"
    assert_equal err, "some error\n"
    assert_equal status.success?, true
  end

  def test_execute_must_return_appropriate_status_for_a_failed_process
    status, out, err = Shellout.execute("ruby -e 'exit(1)'")

    assert_equal status.success?, false
  end

  def test_execute_must_not_hang_when_io_buffer_is_full
    assert_nothing_raised do
      Timeout::timeout(1) do
        Shellout.execute("ruby -e 'STDERR.puts(%[some line\n] * 10000)'")
      end
    end
  end
end
