require 'spec_helper'

describe 'Hg::Activity' do
  it 'must fetch tags' do
    with_hg_repository('hg') do |hg|
      time = Time.parse('Mon Sep 19 15:27:19 2022 +0000')
      assert_equal hg.activity.tags.first, ['tip', '6', time]
      assert_equal hg.activity.tags.last.first(2), ['tagname with space', '2']
    end
  end

  it 'must export repo data' do
    with_hg_repository('hg') do |hg|
      Dir.mktmpdir do |dir|
        hg.activity.export(dir)
        entries = ['.', '..', '.hgtags', 'Gemfile.lock', 'Godeps', 'README', 'makefile', 'nested', 'two']
        assert_equal Dir.entries(dir).sort, entries
      end
    end
  end

  describe 'commits' do
    it 'commit_count' do
      with_hg_repository('hg') do |hg|
        assert_equal hg.activity.commit_count, 6
        assert_equal hg.activity.commit_count(after: 'b14fa4692f949940bd1e28da6fb4617de2615484'), 4
        assert_equal hg.activity.commit_count(after: '655f04cf6ad708ab58c7b941672dce09dd369a18'), 1
      end
    end

    it 'commit_count_with_empty_branch' do
      with_hg_repository('hg', '') do |hg|
        assert_nil hg.scm.branch_name
        assert_equal hg.activity.commit_count, 6
        assert_equal hg.activity.commit_count(after: 'b14fa4692f949940bd1e28da6fb4617de2615484'), 4
        assert_equal hg.activity.commit_count(after: '655f04cf6ad708ab58c7b941672dce09dd369a18'), 1
      end
    end

    it 'commits' do
      with_hg_repository('hg') do |hg|
        assert_equal hg.activity.commits.map(&:token), %w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                                          b14fa4692f949940bd1e28da6fb4617de2615484
                                                          468336c6671cbc58237a259d1b7326866afc2817
                                                          75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                          655f04cf6ad708ab58c7b941672dce09dd369a18
                                                          1f45520fff3982761cfe7a0502ad0888d5783efe]

        after = '655f04cf6ad708ab58c7b941672dce09dd369a18'
        assert_equal hg.activity.commits(after: after).map(&:token), ['1f45520fff3982761cfe7a0502ad0888d5783efe']

        # Check that the diffs are not populated
        assert_empty hg.activity.commits(after: '655f04cf6ad708ab58c7b941672dce09dd369a18').first.diffs

        assert_empty hg.activity.commits(after: '1f45520fff3982761cfe7a0502ad0888d5783efe')
      end
    end

    it 'commits_with_branch' do
      with_hg_repository('hg', 'develop') do |hg|
        assert_equal hg.activity.commits.map(&:token), %w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                                          b14fa4692f949940bd1e28da6fb4617de2615484
                                                          468336c6671cbc58237a259d1b7326866afc2817
                                                          75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                          4d54c3f0526a1ec89214a70615a6b1c6129c665c]

        after = '75532c1e1f1de55c2271f6fd29d98efbe35397c4'
        assert_equal hg.activity.commits(after: after).map(&:token), ['4d54c3f0526a1ec89214a70615a6b1c6129c665c']

        # Check that the diffs are not populated
        assert_empty hg.activity.commits(after: '75532c1e1f1de55c2271f6fd29d98efbe35397c4').first.diffs

        assert_empty hg.activity.commits(after: '4d54c3f0526a1ec89214a70615a6b1c6129c665c')
      end
    end

    it 'trunk_only_commit_count' do
      with_hg_repository('hg_dupe_delete') do |hg|
        assert_equal hg.activity.commit_count(trunk_only: false), 4
        assert_equal hg.activity.commit_count(trunk_only: true), 3
      end
    end

    it 'trunk_only_commits' do
      with_hg_repository('hg_dupe_delete') do |hg|
        assert_equal hg.activity.commits(trunk_only: true)
                       .map(&:token), ['73e93f57224e3fd828cf014644db8eec5013cd6b',
                                       '732345b1d5f4076498132fd4b965b1fec0108a50',
                                       # '525de321d8085bc1d4a3c7608fda6b4020027985', # branch
                                       '72fe74d643bdcb30b00da3b58796c50f221017d0']
      end
    end

    it 'each_commit' do
      commits = []
      with_hg_repository('hg') do |hg|
        hg.activity.each_commit do |c|
          assert c.token.length == 40
          assert c.committer_name
          assert c.committer_date.is_a?(Time)
          refute c.message.empty?
          assert c.diffs.any?
          # Check that the diffs are populated
          c.diffs.each do |d|
            assert d.action =~ /^[MAD]$/
            refute d.path.empty?
          end
          commits << c
        end

        refute File.exist?(hg.activity.send(:log_filename)) # Make sure we cleaned up after ourselves

        # Verify that we got the commits in forward chronological order
        assert_equal commits.map(&:token), %w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                              b14fa4692f949940bd1e28da6fb4617de2615484
                                              468336c6671cbc58237a259d1b7326866afc2817
                                              75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                              655f04cf6ad708ab58c7b941672dce09dd369a18
                                              1f45520fff3982761cfe7a0502ad0888d5783efe]
      end
    end

    it 'each_commit_for_branch' do
      commits = []

      with_hg_repository('hg', 'develop') do |hg|
        commits = hg.activity.each_commit
      end

      assert_equal commits.map(&:token), %w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                            b14fa4692f949940bd1e28da6fb4617de2615484
                                            468336c6671cbc58237a259d1b7326866afc2817
                                            75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                            4d54c3f0526a1ec89214a70615a6b1c6129c665c]
    end

    it 'each_commit_after' do
      commits = []
      with_hg_repository('hg') do |hg|
        hg.activity.each_commit(after: '468336c6671cbc58237a259d1b7326866afc2817') do |c|
          commits << c
        end
        assert_equal commits.map(&:token), %w[75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                              655f04cf6ad708ab58c7b941672dce09dd369a18
                                              1f45520fff3982761cfe7a0502ad0888d5783efe]
      end
    end

    it 'open_log_file_encoding' do
      with_hg_repository('hg_with_invalid_encoding') do |hg|
        hg.activity.send(:open_log_file) do |io|
          assert_equal io.read.valid_encoding?, true
        end
      end
    end

    it 'commits_encoding' do
      with_hg_repository('hg_with_invalid_encoding') do |hg|
        hg.activity.commits
      end
    end

    it 'verbose_commit_encoding' do
      with_hg_repository('hg_with_invalid_encoding') do |hg|
        hg.activity.verbose_commit('51ea5277ca27')
      end
    end
  end

  describe 'head' do
    it 'hg_head_and_parents' do
      with_hg_repository('hg') do |hg|
        assert_equal hg.activity.head_token, '1f45520fff3982761cfe7a0502ad0888d5783efe'
        assert_equal hg.activity.head.token, '1f45520fff3982761cfe7a0502ad0888d5783efe'
        assert hg.activity.head.diffs.any? # diffs should be populated
      end
    end

    it 'head_with_branch' do
      with_hg_repository('hg', 'develop') do |hg|
        assert_equal hg.activity.head.token, '4d54c3f0526a1ec89214a70615a6b1c6129c665c'
        assert hg.activity.head.diffs.any?
      end
    end
  end

  describe 'commit_tokens' do
    it 'must work with after argument' do
      with_hg_repository('hg') do |hg|
        assert_equal hg.activity.commit_tokens, %w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                                   b14fa4692f949940bd1e28da6fb4617de2615484
                                                   468336c6671cbc58237a259d1b7326866afc2817
                                                   75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                   655f04cf6ad708ab58c7b941672dce09dd369a18
                                                   1f45520fff3982761cfe7a0502ad0888d5783efe]

        after = '01101d8ef3cea7da9ac6e9a226d645f4418f05c9'
        assert_equal hg.activity.commit_tokens(after: after), %w[b14fa4692f949940bd1e28da6fb4617de2615484
                                                                 468336c6671cbc58237a259d1b7326866afc2817
                                                                 75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                                 655f04cf6ad708ab58c7b941672dce09dd369a18
                                                                 1f45520fff3982761cfe7a0502ad0888d5783efe]

        after = '655f04cf6ad708ab58c7b941672dce09dd369a18'
        assert_equal hg.activity.commit_tokens(after: after), ['1f45520fff3982761cfe7a0502ad0888d5783efe']

        assert_empty hg.activity.commit_tokens(after: '1f45520fff3982761cfe7a0502ad0888d5783efe')
      end
    end

    it 'must work with trunk_only argument' do
      with_hg_repository('hg_dupe_delete') do |hg|
        assert_equal hg.activity.commit_tokens(trunk_only: false), %w[73e93f57224e3fd828cf014644db8eec5013cd6b
                                                                      732345b1d5f4076498132fd4b965b1fec0108a50
                                                                      525de321d8085bc1d4a3c7608fda6b4020027985
                                                                      72fe74d643bdcb30b00da3b58796c50f221017d0]

        assert_equal hg.activity.commit_tokens(trunk_only: true),
                     ['73e93f57224e3fd828cf014644db8eec5013cd6b', '732345b1d5f4076498132fd4b965b1fec0108a50',
                      # '525de321d8085bc1d4a3c7608fda6b4020027985', # branch
                      '72fe74d643bdcb30b00da3b58796c50f221017d0']
      end
    end

    it 'must work with trunk_only and after arguments' do
      with_hg_repository('hg_dupe_delete') do |hg|
        opts = { after: '73e93f57224e3fd828cf014644db8eec5013cd6b', trunk_only: false }
        assert_equal hg.activity.commit_tokens(opts), %w[732345b1d5f4076498132fd4b965b1fec0108a50
                                                         525de321d8085bc1d4a3c7608fda6b4020027985
                                                         72fe74d643bdcb30b00da3b58796c50f221017d0]

        opts = { after: '73e93f57224e3fd828cf014644db8eec5013cd6b', trunk_only: true }
        assert_equal hg.activity.commit_tokens(opts), ['732345b1d5f4076498132fd4b965b1fec0108a50',
                                                       # '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
                                                       '72fe74d643bdcb30b00da3b58796c50f221017d0']

        assert_empty hg.activity.commit_tokens(after: '72fe74d643bdcb30b00da3b58796c50f221017d0', trunk_only: true)
      end
    end

    it 'must work with after and upto arguments' do
      with_hg_repository('hg_walk') do |hg|
        commit_tokens = CommitTokensHelper.new(hg, commit_labels)
        # Full history to a commit
        assert_equal commit_tokens.between(nil, :A), %i[A]
        assert_equal commit_tokens.between(nil, :B), %i[A B]
        assert_equal commit_tokens.between(nil, :C), %i[A B G H C]
        assert_equal commit_tokens.between(nil, :D), %i[A B G H C I D]
        assert_equal commit_tokens.between(nil, :G), %i[A B G]
        assert_equal commit_tokens.between(nil, :H), %i[A B G H]
        assert_equal commit_tokens.between(nil, :I), %i[A B G H C I]

        # Limited history from one commit to another
        assert_empty commit_tokens.between(:A, :A)
        assert_equal commit_tokens.between(:A, :B), %i[B]
        assert_equal commit_tokens.between(:A, :C), %i[B G H C]
        assert_equal commit_tokens.between(:A, :D), %i[B G H C I D]
        assert_equal commit_tokens.between(:B, :D), %i[G H C I D]
        assert_equal commit_tokens.between(:C, :D), %i[I D]
      end
    end

    def commit_labels
      { A: '4bfbf836feeebb236492199fbb0d1474e26f69d9',
        B: '23edb79d0d06c8c315d8b9e7456098823335377d',
        C: '7e33b9fde56a6e3576753868d08fa143e4e8a9cf',
        D: '8daa1aefa228d3ee5f9a0f685d696826e88266fb',
        G: 'e43cf1bb4b80d8ae70a695ec070ce017fdc529f3',
        H: 'dca215d8a3e4dd3e472379932f1dd9c909230331',
        I: '3a1495175e40b1c983441d6a8e8e627d2bd672b6' }
    end
  end

  describe 'cat' do
    it 'must get file contents by current or parent commit' do
      with_hg_repository('hg') do |hg|
        expected = <<-EXPECTED.gsub(/ {10}/, '')
          /* Hello, World! */

          /*
           * This file is not covered by any license, especially not
           * the GNU General Public License (GPL). Have fun!
           */

          #include <stdio.h>
          main()
          {
          	printf("Hello, World!\\n");
          }
        EXPECTED

        diff = OhlohScm::Diff.new(path: 'helloworld.c')
        commit = OhlohScm::Commit.new(token: '75532c1e1f1d')
        # The file was deleted in revision 468336c6671c. Check that it does not exist now, but existed in parent.
        assert_nil hg.activity.cat_file(commit, diff)
        assert_equal hg.activity.cat_file_parent(commit, diff), expected
        assert_equal hg.activity.cat_file(OhlohScm::Commit.new(token: '468336c6671c'), diff), expected
      end
    end

    # Ensure that we escape bash-significant characters like ' and & when they appear in the filename
    it 'must handle funny file names' do
      tmpdir do |dir|
        # Make a file with a problematic filename
        funny_name = '#|file_name` $(&\'")#'
        file_content = 'foobar'
        File.write(File.join(dir, funny_name), file_content)

        # Add it to an hg repository
        `cd #{dir} && hg init && hg add * 2> /dev/null && hg commit -u tester -m test`

        # Confirm that we can read the file back
        hg = OhlohScm::Factory.get_core(scm_type: :hg, url: dir)
        diff = OhlohScm::Diff.new(path: funny_name)
        assert_equal hg.activity.cat_file(hg.activity.head, diff), file_content
      end
    end
  end

  describe 'cleanup' do
    it 'must call shutdown hg_client' do
      activity = OhlohScm::Factory.get_core(scm_type: :hg, url: 'foobar').activity
      hg_client = Struct.new(:foo)
      activity.stubs(:hg_client).returns(hg_client)
      hg_client.expects(:shutdown)
      activity.cleanup
    end
  end
end
