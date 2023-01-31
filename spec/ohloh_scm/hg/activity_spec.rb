require 'spec_helper'

describe 'Hg::Activity' do
  it 'must fetch tags' do
    with_hg_repository('hg') do |hg|
      time = Time.parse('Mon Sep 19 15:27:19 2022 +0000')
      hg.activity.tags.first.must_equal ['tip', '6', time]
      hg.activity.tags.last.first(2).must_equal ['tagname with space', '2']
    end
  end

  it 'must export repo data' do
    with_hg_repository('hg') do |hg|
      Dir.mktmpdir do |dir|
        hg.activity.export(dir)
        entries = [".", "..", ".hgtags", "Gemfile.lock", "Godeps", "README", "makefile", "nested", "two"]
        Dir.entries(dir).sort.must_equal entries
      end
    end
  end

  describe 'commits' do
    it 'commit_count' do
      with_hg_repository('hg') do |hg|
        hg.activity.commit_count.must_equal 6
        hg.activity.commit_count(after: 'b14fa4692f949940bd1e28da6fb4617de2615484').must_equal 4
        hg.activity.commit_count(after: '655f04cf6ad708ab58c7b941672dce09dd369a18').must_equal 1
      end
    end

    it 'commit_count_with_empty_branch' do
      with_hg_repository('hg', '') do |hg|
        hg.scm.branch_name.must_be_nil
        hg.activity.commit_count.must_equal 6
        hg.activity.commit_count(after: 'b14fa4692f949940bd1e28da6fb4617de2615484').must_equal 4
        hg.activity.commit_count(after: '655f04cf6ad708ab58c7b941672dce09dd369a18').must_equal 1
      end
    end

    it 'commits' do
      with_hg_repository('hg') do |hg|
        hg.activity.commits.map(&:token).must_equal(%w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                                       b14fa4692f949940bd1e28da6fb4617de2615484
                                                       468336c6671cbc58237a259d1b7326866afc2817
                                                       75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                       655f04cf6ad708ab58c7b941672dce09dd369a18
                                                       1f45520fff3982761cfe7a0502ad0888d5783efe])

        after = '655f04cf6ad708ab58c7b941672dce09dd369a18'
        hg.activity.commits(after: after).map(&:token).must_equal ['1f45520fff3982761cfe7a0502ad0888d5783efe']

        # Check that the diffs are not populated
        hg.activity.commits(after: '655f04cf6ad708ab58c7b941672dce09dd369a18').first.diffs.must_be :empty?

        hg.activity.commits(after: '1f45520fff3982761cfe7a0502ad0888d5783efe').must_be :empty?
      end
    end

    it 'commits_with_branch' do
      with_hg_repository('hg', 'develop') do |hg|
        hg.activity.commits.map(&:token).must_equal(%w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                                       b14fa4692f949940bd1e28da6fb4617de2615484
                                                       468336c6671cbc58237a259d1b7326866afc2817
                                                       75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                       4d54c3f0526a1ec89214a70615a6b1c6129c665c])

        after = '75532c1e1f1de55c2271f6fd29d98efbe35397c4'
        hg.activity.commits(after: after).map(&:token).must_equal(['4d54c3f0526a1ec89214a70615a6b1c6129c665c'])

        # Check that the diffs are not populated
        hg.activity.commits(after: '75532c1e1f1de55c2271f6fd29d98efbe35397c4').first.diffs.must_be :empty?

        hg.activity.commits(after: '4d54c3f0526a1ec89214a70615a6b1c6129c665c').must_be :empty?
      end
    end

    it 'trunk_only_commit_count' do
      with_hg_repository('hg_dupe_delete') do |hg|
        hg.activity.commit_count(trunk_only: false).must_equal 4
        hg.activity.commit_count(trunk_only: true).must_equal 3
      end
    end

    it 'trunk_only_commits' do
      with_hg_repository('hg_dupe_delete') do |hg|
        hg.activity.commits(trunk_only: true)
          .map(&:token).must_equal(['73e93f57224e3fd828cf014644db8eec5013cd6b',
                                    '732345b1d5f4076498132fd4b965b1fec0108a50',
                                    # '525de321d8085bc1d4a3c7608fda6b4020027985', # branch
                                    '72fe74d643bdcb30b00da3b58796c50f221017d0'])
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
        commits.map(&:token).must_equal(%w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                           b14fa4692f949940bd1e28da6fb4617de2615484
                                           468336c6671cbc58237a259d1b7326866afc2817
                                           75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                           655f04cf6ad708ab58c7b941672dce09dd369a18
                                           1f45520fff3982761cfe7a0502ad0888d5783efe])
      end
    end

    it 'each_commit_for_branch' do
      commits = []

      with_hg_repository('hg', 'develop') do |hg|
        commits = hg.activity.each_commit
      end

      commits.map(&:token).must_equal(%w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                         b14fa4692f949940bd1e28da6fb4617de2615484
                                         468336c6671cbc58237a259d1b7326866afc2817
                                         75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                         4d54c3f0526a1ec89214a70615a6b1c6129c665c])
    end

    it 'each_commit_after' do
      commits = []
      with_hg_repository('hg') do |hg|
        hg.activity.each_commit(after: '468336c6671cbc58237a259d1b7326866afc2817') do |c|
          commits << c
        end
        commits.map(&:token).must_equal(%w[75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                           655f04cf6ad708ab58c7b941672dce09dd369a18
                                           1f45520fff3982761cfe7a0502ad0888d5783efe])
      end
    end

    it 'open_log_file_encoding' do
      with_hg_repository('hg_with_invalid_encoding') do |hg|
        hg.activity.send(:open_log_file) do |io|
          io.read.valid_encoding?.must_equal true
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
        hg.activity.head_token.must_equal '1f45520fff3982761cfe7a0502ad0888d5783efe'
        hg.activity.head.token.must_equal '1f45520fff3982761cfe7a0502ad0888d5783efe'
        assert hg.activity.head.diffs.any? # diffs should be populated
      end
    end

    it 'head_with_branch' do
      with_hg_repository('hg', 'develop') do |hg|
        hg.activity.head.token.must_equal '4d54c3f0526a1ec89214a70615a6b1c6129c665c'
        assert hg.activity.head.diffs.any?
      end
    end
  end

  describe 'commit_tokens' do
    it 'must work with after argument' do
      with_hg_repository('hg') do |hg|
        hg.activity.commit_tokens.must_equal(%w[01101d8ef3cea7da9ac6e9a226d645f4418f05c9
                                                b14fa4692f949940bd1e28da6fb4617de2615484
                                                468336c6671cbc58237a259d1b7326866afc2817
                                                75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                655f04cf6ad708ab58c7b941672dce09dd369a18
                                                1f45520fff3982761cfe7a0502ad0888d5783efe])

        after = '01101d8ef3cea7da9ac6e9a226d645f4418f05c9'
        hg.activity.commit_tokens(after: after).must_equal(%w[b14fa4692f949940bd1e28da6fb4617de2615484
                                                              468336c6671cbc58237a259d1b7326866afc2817
                                                              75532c1e1f1de55c2271f6fd29d98efbe35397c4
                                                              655f04cf6ad708ab58c7b941672dce09dd369a18
                                                              1f45520fff3982761cfe7a0502ad0888d5783efe])

        after = '655f04cf6ad708ab58c7b941672dce09dd369a18'
        hg.activity.commit_tokens(after: after).must_equal ['1f45520fff3982761cfe7a0502ad0888d5783efe']

        hg.activity.commit_tokens(after: '1f45520fff3982761cfe7a0502ad0888d5783efe').must_be :empty?
      end
    end

    it 'must work with trunk_only argument' do
      with_hg_repository('hg_dupe_delete') do |hg|
        hg.activity.commit_tokens(trunk_only: false).must_equal(%w[73e93f57224e3fd828cf014644db8eec5013cd6b
                                                                   732345b1d5f4076498132fd4b965b1fec0108a50
                                                                   525de321d8085bc1d4a3c7608fda6b4020027985
                                                                   72fe74d643bdcb30b00da3b58796c50f221017d0])

        hg.activity.commit_tokens(trunk_only: true).must_equal(['73e93f57224e3fd828cf014644db8eec5013cd6b',
                                                                '732345b1d5f4076498132fd4b965b1fec0108a50',
                                                                # '525de321d8085bc1d4a3c7608fda6b4020027985', # branch
                                                                '72fe74d643bdcb30b00da3b58796c50f221017d0'])
      end
    end

    it 'must work with trunk_only and after arguments' do
      with_hg_repository('hg_dupe_delete') do |hg|
        opts = { after: '73e93f57224e3fd828cf014644db8eec5013cd6b', trunk_only: false }
        hg.activity.commit_tokens(opts).must_equal(%w[732345b1d5f4076498132fd4b965b1fec0108a50
                                                      525de321d8085bc1d4a3c7608fda6b4020027985
                                                      72fe74d643bdcb30b00da3b58796c50f221017d0])

        opts = { after: '73e93f57224e3fd828cf014644db8eec5013cd6b', trunk_only: true }
        hg.activity.commit_tokens(opts).must_equal(['732345b1d5f4076498132fd4b965b1fec0108a50',
                                                    # '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
                                                    '72fe74d643bdcb30b00da3b58796c50f221017d0'])

        hg.activity.commit_tokens(after: '72fe74d643bdcb30b00da3b58796c50f221017d0', trunk_only: true).must_be :empty?
      end
    end

    it 'must work with after and upto arguments' do
      with_hg_repository('hg_walk') do |hg|
        commit_tokens = CommitTokensHelper.new(hg, commit_labels)
        # Full history to a commit
        commit_tokens.between(nil, :A).must_equal %i[A]
        commit_tokens.between(nil, :B).must_equal %i[A B]
        commit_tokens.between(nil, :C).must_equal %i[A B G H C]
        commit_tokens.between(nil, :D).must_equal %i[A B G H C I D]
        commit_tokens.between(nil, :G).must_equal %i[A B G]
        commit_tokens.between(nil, :H).must_equal %i[A B G H]
        commit_tokens.between(nil, :I).must_equal %i[A B G H C I]

        # Limited history from one commit to another
        commit_tokens.between(:A, :A).must_be :empty?
        commit_tokens.between(:A, :B).must_equal %i[B]
        commit_tokens.between(:A, :C).must_equal %i[B G H C]
        commit_tokens.between(:A, :D).must_equal %i[B G H C I D]
        commit_tokens.between(:B, :D).must_equal %i[G H C I D]
        commit_tokens.between(:C, :D).must_equal %i[I D]
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
        hg.activity.cat_file(commit, diff).must_be_nil
        hg.activity.cat_file_parent(commit, diff).must_equal expected
        hg.activity.cat_file(OhlohScm::Commit.new(token: '468336c6671c'), diff).must_equal expected
      end
    end

    # Ensure that we escape bash-significant characters like ' and & when they appear in the filename
    it 'must handle funny file names' do
      tmpdir do |dir|
        # Make a file with a problematic filename
        funny_name = '#|file_name` $(&\'")#'
        file_content = 'foobar'
        File.open(File.join(dir, funny_name), 'w') { |f| f.write file_content }

        # Add it to an hg repository
        `cd #{dir} && hg init && hg add * 2> /dev/null && hg commit -u tester -m test`

        # Confirm that we can read the file back
        hg = OhlohScm::Factory.get_core(scm_type: :hg, url: dir)
        diff = OhlohScm::Diff.new(path: funny_name)
        hg.activity.cat_file(hg.activity.head, diff).must_equal file_content
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
