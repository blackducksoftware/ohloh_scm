require 'spec_helper'

describe 'HgParser' do
  describe 'parser' do
    it 'must return an empty list for blank log' do
      OhlohScm::HgParser.parse('').must_be :empty?
    end

    it 'must parse log into commits' do
      sample_log = <<-SAMPLE.gsub(/^ {8}/, '')
        __BEGIN_COMMIT__
        changeset: 655f04cf6ad708ab58c7b941672dce09dd369a18
        user:      Alex <alex@example.com>
        date:      1232479997.028800
        __BEGIN_COMMENT__
        added makefile
        __END_COMMENT__
        __END_COMMIT__
        __BEGIN_COMMIT__
        changeset: 01101d8ef3cea7da9ac6e9a226d645f4418f05c9
        user:      Robin Luckey <robin@ohloh.net>
        date:      1232479974.028800
        __BEGIN_COMMENT__
        Initial Checkin
        __END_COMMENT__
        __END_COMMIT__

      SAMPLE

      commits = OhlohScm::HgParser.parse(sample_log)

      assert commits
      commits.size.must_equal 2

      commits[0].token.must_match '655f04cf6ad708'
      commits[0].committer_name.must_equal 'Alex'
      commits[0].committer_email.must_equal 'alex@example.com'
      commits[0].message.must_equal "added makefile\n" # Note \n at end of comment
      commits[0].committer_date.to_i.must_equal Time.utc(2009, 1, 20, 19, 33, 17).to_i
      commits[0].diffs.size.must_equal 0

      commits[1].token.must_match '01101d8ef3ce'
      commits[1].committer_name.must_equal 'Robin Luckey'
      commits[1].committer_email.must_equal 'robin@ohloh.net'
      commits[1].message.must_equal "Initial Checkin\n" # Note \n at end of comment
      commits[1].committer_date.to_i.must_equal Time.utc(2009, 1, 20, 19, 32, 54).to_i
      commits[1].diffs.size.must_equal 0
    end

    it 'must set committer_name to email and committer_email to NULL when name is not present' do
      sample_log = <<-SAMPLE.gsub(/^ {8}/, '')
        __BEGIN_COMMIT__
        changeset: 01101d8ef3cea7da9ac6e9a226d645f4418f05c9
        user:      robin@ohloh.net
        date:      1232479974.028800
        __BEGIN_COMMENT__
        Initial Checkin
        __END_COMMENT__
        __END_COMMIT__
      SAMPLE

      commits = OhlohScm::HgParser.parse(sample_log)

      assert commits
      commits.size.must_equal 1

      commits[0].token.must_match '01101d8ef3ce'
      commits[0].committer_name.must_equal 'robin@ohloh.net'
      commits[0].committer_email.must_be_nil
    end

    # Sometimes the log does not include a summary
    it 'must parse log with no summary' do
      sample_log = <<-SAMPLE.gsub(/^ {8}/, '')
        __BEGIN_COMMIT__
        changeset: 655f04cf6ad708ab58c7b941672dce09dd369a18
        user:      Alex <alex@example.com>
        date:      1232479997.028800
        __END_COMMIT__
        __BEGIN_COMMIT__
        changeset: 01101d8ef3cea7da9ac6e9a226d645f4418f05c9
        user:      Robin Luckey <robin@ohloh.net>
        date:      1232479974.028800
        __END_COMMIT__
      SAMPLE
      commits = OhlohScm::HgParser.parse(sample_log)

      assert commits
      commits.size.must_equal 2

      commits[0].token.must_match '655f04cf6ad708'
      commits[0].committer_name.must_equal 'Alex'
      commits[0].committer_email.must_equal 'alex@example.com'
      commits[0].message.must_be_nil
      commits[0].committer_date.to_i.must_equal Time.utc(2009, 1, 20, 19, 33, 17).to_i
      commits[0].diffs.size.must_equal 0
    end

    it 'must parse verbose log into commits and diffs' do
      sample_log = <<-SAMPLE.gsub(/^ {8}/, '')
        __BEGIN_COMMIT__
        changeset: 655f04cf6ad708ab58c7b941672dce09dd369a18
        user:      Alex <alex@example.com>
        date:      1232479997.028800
        __BEGIN_COMMENT__
        Adding file foobar
        __END_COMMENT__
        __BEGIN_FILES__
        A foobar
        __END_FILES__
        __END_COMMIT__

        __BEGIN_COMMIT__
        changeset: 01101d8ef3cea7da9ac6e9a226d645f4418f05c9
        user:      Robin Luckey <robin@ohloh.net>
        date:      1232479974.028800
        __BEGIN_COMMENT__
        Initial Checkin
        __END_COMMENT__
        __BEGIN_FILES__
        A helloworld.c
        __END_FILES__
        __END_COMMIT__
      SAMPLE

      commits = OhlohScm::HgParser.parse(sample_log)

      assert commits
      commits.size.must_equal 2

      commits[0].token.must_match '655f04cf6ad708'
      commits[0].committer_name.must_equal 'Alex'
      commits[0].committer_email.must_equal 'alex@example.com'
      commits[0].message.must_equal "Adding file foobar\n" # Note \n at end of comment
      commits[0].committer_date.to_i.must_equal Time.utc(2009, 1, 20, 19, 33, 17).to_i
      commits[0].diffs[0].path.must_equal 'foobar'

      commits[1].token.must_match '01101d8ef3ce'
      commits[1].committer_name.must_equal 'Robin Luckey'
      commits[1].committer_email.must_equal 'robin@ohloh.net'
      commits[1].message.must_equal "Initial Checkin\n" # Note \n at end of comment
      commits[1].committer_date.to_i.must_equal Time.utc(2009, 1, 20, 19, 32, 54).to_i
      commits[1].diffs.size.must_equal 1
      commits[1].diffs[0].path.must_equal 'helloworld.c'
    end

    it 'must parse log with the --style argument' do
      with_hg_repository('hg') do |hg|
        assert File.exist?(OhlohScm::HgParser.style_path)
        log = run_p("cd #{hg.scm.url} && hg log -f --style #{OhlohScm::HgParser.style_path}")
        commits = OhlohScm::HgParser.parse(log)
        assert_styled_commits(commits, false)

        assert File.exist?(OhlohScm::HgParser.verbose_style_path)
        log = run_p("cd #{hg.scm.url} && hg log -f --style #{OhlohScm::HgParser.verbose_style_path}")
        commits = OhlohScm::HgParser.parse(log)
        assert_styled_commits(commits, true)
      end
    end

    protected

    def assert_styled_commits(commits, with_diffs = false)
      commits.size.must_equal 6

      commits[1].token.must_equal '655f04cf6ad708ab58c7b941672dce09dd369a18'
      commits[1].committer_name.must_equal 'Alex'
      commits[1].committer_email.must_equal 'alex@example.com'
      assert Time.utc(2009, 1, 20, 19, 34, 53) - commits[1].committer_date < 1 # Don't care about milliseconds
      commits[1].message.must_equal "Adding file two\n"

      if with_diffs
        commits[1].diffs.size.must_equal 1
        commits[1].diffs[0].action.must_equal 'A'
        commits[1].diffs[0].path.must_equal 'two'
      else
        commits[1].diffs.must_equal []
      end

      commits[2].token.must_equal '75532c1e1f1de55c2271f6fd29d98efbe35397c4'
      assert Time.utc(2009, 1, 20, 19, 34, 4) - commits[2].committer_date < 1

      if with_diffs
        commits[3].diffs.size.must_equal 2
        commits[3].diffs[0].action.must_equal 'M'
        commits[3].diffs[0].path.must_equal 'helloworld.c'
        commits[3].diffs[1].action.must_equal 'A'
        commits[3].diffs[1].path.must_equal 'README'
      else
        commits[0].diffs.must_equal []
      end
    end
  end
end
