require 'spec_helper'

DATA_DIR = File.expand_path(File.join(File.dirname(__FILE__), '../raw_fixtures'))

describe 'SvnParser' do
  it 'test_empty_array' do
    assert_predicate OhlohScm::SvnParser.parse(''), :empty?
  end

  it 'test_yield_instead_of_writer' do
    commits = []
    result = OhlohScm::SvnParser.parse(File.read("#{DATA_DIR}/simple.svn_log")) do |commit|
      commits << commit.token
    end
    assert_nil result
    assert_equal commits, [5, 4, 3, 2, 1]
  end

  it 'test_log_parser' do
    sample_log = <<~SAMPLE
      ------------------------------------------------------------------------
      r1 | robin | 2006-06-11 11:28:00 -0700 (Sun, 11 Jun 2006) | 2 lines

      Initial Checkin

      ------------------------------------------------------------------------
      r2 | jason | 2006-06-11 11:32:13 -0700 (Sun, 11 Jun 2006) | 1 line

      added makefile
      ------------------------------------------------------------------------
      r3 | robin | 2006-06-11 11:34:17 -0700 (Sun, 11 Jun 2006) | 1 line

      added some documentation and licensing info
      ------------------------------------------------------------------------
    SAMPLE

    revs = OhlohScm::SvnParser.parse(sample_log)

    assert revs
    assert_equal revs.size, 3

    assert_equal revs[0].token, 1
    assert_equal revs[0].committer_name, 'robin'
    assert_equal revs[0].message, "Initial Checkin\n" # Note \n at end of comment
    assert_equal revs[0].committer_date, Time.utc(2006, 6, 11, 18, 28, 0o0)

    assert_equal revs[1].token, 2
    assert_equal revs[1].committer_name, 'jason'
    assert_equal revs[1].message, 'added makefile' # Note no \n at end of comment
    assert_equal revs[1].committer_date, Time.utc(2006, 6, 11, 18, 32, 13)

    assert_equal revs[2].token, 3
    assert_equal revs[2].committer_name, 'robin'
    assert_equal revs[2].message, 'added some documentation and licensing info'
    assert_equal revs[2].committer_date, Time.utc(2006, 6, 11, 18, 34, 17)
  end

  # This is an excerpt from the log for Wireshark. It includes Subversion log excerpts in
  # its comments, which really screwed us up. This test confirms that I've fixed the
  # parser to ignore log excerpts in the comments.
  it 'test_log_embedded_in_comments' do
    log = <<~LOG
      ------------------------------------------------------------------------
      r21932 | jmayer | 2007-05-25 01:34:15 -0700 (Fri, 25 May 2007) | 22 lines

      Update from samba tree revision 23054 to 23135
      ============================ Samba log start ============
      ------------------------------------------------------------------------
      r23069 | metze | 2007-05-22 13:23:36 +0200 (Tue, 22 May 2007) | 3 lines
      Changed paths:
         M /branches/SAMBA_4_0/source/pidl/tests/Util.pm

       print out the command, to find out the problem on host 'tridge'

       metze
      ------------------------------------------------------------------------
      r23071 | metze | 2007-05-22 14:45:58 +0200 (Tue, 22 May 2007) | 3 lines
      Changed paths:
         M /branches/SAMBA_4_0/source/pidl/tests/Util.pm

       print the command on failure only

       metze
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
      ============================ Samba log end ==============

       ------------------------------------------------------------------------
      r21931 | kukosa | 2007-05-24 23:54:39 -0700 (Thu, 24 May 2007) | 2 lines

       UMTS RRC updated to 3GPP TS 25.331 V7.4.0 (2007-03) and moved to one directory

       ------------------------------------------------------------------------
    LOG
    revs = OhlohScm::SvnParser.parse(log)

    assert revs
    assert_equal revs.size, 2

    assert_equal revs[0].token, 21_932
    assert_equal revs[1].token, 21_931

    comment = <<~COMMENT
      Update from samba tree revision 23054 to 23135
      ============================ Samba log start ============
      ------------------------------------------------------------------------
      r23069 | metze | 2007-05-22 13:23:36 +0200 (Tue, 22 May 2007) | 3 lines
      Changed paths:
         M /branches/SAMBA_4_0/source/pidl/tests/Util.pm

       print out the command, to find out the problem on host 'tridge'

       metze
      ------------------------------------------------------------------------
      r23071 | metze | 2007-05-22 14:45:58 +0200 (Tue, 22 May 2007) | 3 lines
      Changed paths:
         M /branches/SAMBA_4_0/source/pidl/tests/Util.pm

       print the command on failure only

       metze
      ------------------------------------------------------------------------
      ------------------------------------------------------------------------
      ============================ Samba log end ==============
    COMMENT
    assert_equal revs[0].message, comment
  end

  it 'test_svn_copy' do
    log = <<~LOG
      ------------------------------------------------------------------------
      r8 | robin | 2009-02-05 05:40:46 -0800 (Thu, 05 Feb 2009) | 1 line
      Changed paths:
         A /trunk (from /branches/development:7)

      the branch becomes the new trunk
    LOG

    commits = OhlohScm::SvnParser.parse(log)
    assert_equal commits.size, 1
    assert_equal commits.first.diffs.size, 1
    assert_equal commits.first.diffs.first.path, '/trunk'
    assert_equal commits.first.diffs.first.from_path, '/branches/development'
    assert_equal commits.first.diffs.first.from_revision, 7
  end
end
