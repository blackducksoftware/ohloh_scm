require 'spec_helper'

describe 'HgParser' do
  describe 'parser' do
    it 'must return an empty list for blank log' do
      assert_empty OhlohScm::HgParser.parse('')
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
      assert_equal commits.size, 2

      assert commits[0].token.match?('655f04cf6ad708')
      assert_equal commits[0].committer_name, 'Alex'
      assert_equal commits[0].committer_email, 'alex@example.com'
      assert_equal commits[0].message, "added makefile\n" # Note \n at end of comment
      assert_equal commits[0].committer_date.to_i, Time.utc(2009, 1, 20, 19, 33, 17).to_i
      assert_equal commits[0].diffs.size, 0

      assert commits[1].token.match?('01101d8ef3ce')
      assert_equal commits[1].committer_name, 'Robin Luckey'
      assert_equal commits[1].committer_email, 'robin@ohloh.net'
      assert_equal commits[1].message, "Initial Checkin\n" # Note \n at end of comment
      assert_equal commits[1].committer_date.to_i, Time.utc(2009, 1, 20, 19, 32, 54).to_i
      assert_equal commits[1].diffs.size, 0
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
      assert_equal commits.size, 1

      assert commits[0].token.match?('01101d8ef3ce')
      assert_equal commits[0].committer_name, 'robin@ohloh.net'
      assert_nil commits[0].committer_email
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
      assert_equal commits.size, 2

      assert commits[0].token.match?('655f04cf6ad708')
      assert_equal commits[0].committer_name, 'Alex'
      assert_equal commits[0].committer_email, 'alex@example.com'
      assert_nil commits[0].message
      assert_equal commits[0].committer_date.to_i, Time.utc(2009, 1, 20, 19, 33, 17).to_i
      assert_equal commits[0].diffs.size, 0
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
      assert_equal commits.size, 2

      assert commits[0].token.match?('655f04cf6ad708')
      assert_equal commits[0].committer_name, 'Alex'
      assert_equal commits[0].committer_email, 'alex@example.com'
      assert_equal commits[0].message, "Adding file foobar\n" # Note \n at end of comment
      assert_equal commits[0].committer_date.to_i, Time.utc(2009, 1, 20, 19, 33, 17).to_i
      assert_equal commits[0].diffs[0].path, 'foobar'

      assert commits[1].token.match?('01101d8ef3ce')
      assert_equal commits[1].committer_name, 'Robin Luckey'
      assert_equal commits[1].committer_email, 'robin@ohloh.net'
      assert_equal commits[1].message, "Initial Checkin\n" # Note \n at end of comment
      assert_equal commits[1].committer_date.to_i, Time.utc(2009, 1, 20, 19, 32, 54).to_i
      assert_equal commits[1].diffs.size, 1
      assert_equal commits[1].diffs[0].path, 'helloworld.c'
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
      assert_equal commits.size, 6

      assert_equal commits[1].token, '655f04cf6ad708ab58c7b941672dce09dd369a18'
      assert_equal commits[1].committer_name, 'Alex'
      assert_equal commits[1].committer_email, 'alex@example.com'
      assert Time.utc(2009, 1, 20, 19, 34, 53) - commits[1].committer_date < 1 # Don't care about milliseconds
      assert_equal commits[1].message, "Adding file two\n"

      if with_diffs
        assert_equal commits[1].diffs.size, 1
        assert_equal commits[1].diffs[0].action, 'A'
        assert_equal commits[1].diffs[0].path, 'two'
      else
        assert_equal commits[1].diffs, []
      end

      assert_equal commits[2].token, '75532c1e1f1de55c2271f6fd29d98efbe35397c4'
      assert Time.utc(2009, 1, 20, 19, 34, 4) - commits[2].committer_date < 1

      if with_diffs
        assert_equal commits[3].diffs.size, 2
        assert_equal commits[3].diffs[0].action, 'M'
        assert_equal commits[3].diffs[0].path, 'helloworld.c'
        assert_equal commits[3].diffs[1].action, 'A'
        assert_equal commits[3].diffs[1].path, 'README'
      else
        assert_equal commits[0].diffs, []
      end
    end
  end
end
