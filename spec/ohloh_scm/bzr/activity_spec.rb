# frozen_string_literal: true

require 'spec_helper'

describe 'Bzr::Activity' do
  it 'must export contents of a repository' do
    with_bzr_repository('bzr') do |bzr|
      tmpdir do |dir|
        bzr.activity.export(dir)
        entries = ['.', '..', 'Cédric.txt', 'file1.txt', 'file3.txt', 'file4.txt', 'file5.txt']
        assert_equal Dir.entries(dir).sort, entries
      end
    end
  end

  it 'must return head and parents correctly' do
    with_bzr_repository('bzr') do |bzr|
      activity = bzr.activity

      assert_equal activity.head_token, 'test@example.com-20111222183733-y91if5npo3pe8ifs'
      assert_equal activity.head.token, 'test@example.com-20111222183733-y91if5npo3pe8ifs'
      assert activity.head.diffs.any? # diffs should be populated

      assert_equal activity.parents(activity.head).first.token, 'obnox@samba.org-20090204004942-73rnw0izen42f154'
      assert activity.parents(activity.head).first.diffs.any?
    end
  end

  it 'must return file contents' do
    with_bzr_repository('bzr') do |bzr|
      expected = <<-EXPECTED.gsub(/ {8}/, '')
        first file
        second line
      EXPECTED

      commit = OhlohScm::Commit.new(token: 6)
      diff = OhlohScm::Diff.new(path: 'file1.txt')
      assert_equal bzr.activity.cat_file(commit, diff), expected

      # file2.txt has been removed in commit #5
      diff2 = OhlohScm::Diff.new(path: 'file2.txt')
      assert_nil bzr.activity.cat_file(bzr.activity.commits.last, diff2)
    end
  end

  it 'cat_file must work with non-ascii name' do
    with_bzr_repository('bzr') do |bzr|
      expected = <<-EXPECTED.gsub(/ {8}/, '')
        first file
        second line
      EXPECTED

      commit = OhlohScm::Commit.new(token: 7)
      diff = OhlohScm::Diff.new(path: 'Cédric.txt')
      assert_equal bzr.activity.cat_file(commit, diff), expected
    end
  end

  it 'must get file contents by parent rev' do
    with_bzr_repository('bzr') do |bzr|
      expected = <<-EXPECTED.gsub(/ {8}/, '')
        first file
        second line
      EXPECTED

      commit = OhlohScm::Commit.new(token: 6)
      diff = OhlohScm::Diff.new(path: 'file1.txt')
      assert_equal bzr.activity.cat_file_parent(commit, diff), expected

      # file2.txt has been removed in commit #5
      expected = <<-EXPECTED.gsub(/ {8}/, '')
        another file
      EXPECTED

      commit2 = OhlohScm::Commit.new(token: 5)
      diff2 = OhlohScm::Diff.new(path: 'file2.txt')
      assert_equal bzr.activity.cat_file_parent(commit2, diff2), expected
    end
  end

  describe 'commits' do
    it 'must test_commit_count' do
      with_bzr_repository('bzr') do |bzr|
        assert_equal bzr.activity.commit_count, 7
        assert_equal bzr.activity.commit_count(after: revision_ids.first), 6
        assert_equal bzr.activity.commit_count(after: revision_ids[5]), 1
        assert_equal bzr.activity.commit_count(after: revision_ids.last), 0
      end
    end

    it 'must test_commit_count_with_branches' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        # Only 3 commits are on main line... make sure we catch the branch commit as well
        assert_equal bzr.activity.commit_count, 4
      end
    end

    it 'must test_commit_count_after_merge' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.activity.commits.last
        assert_equal 0, bzr.activity.commit_count(after: last_commit.token)
      end
    end

    it 'must test_commit_count_trunk_only' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        # Only 3 commits are on main line
        assert_equal bzr.activity.commit_count(trunk_only: true), 3
      end
    end

    it 'must test_commit_tokens_after' do
      with_bzr_repository('bzr') do |bzr|
        assert_equal bzr.activity.commit_tokens, revision_ids
        assert_equal bzr.activity.commit_tokens(after: revision_ids.first), revision_ids[1..6]
        assert_equal bzr.activity.commit_tokens(after: revision_ids[5]), revision_ids[6..6]
        assert_equal bzr.activity.commit_tokens(after: revision_ids.last), []
      end
    end

    it 'must test_commit_tokens_after_merge' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.activity.commits.last
        assert_equal [], bzr.activity.commit_tokens(after: last_commit.token)
      end
    end

    it 'must test_commit_tokens_after_nested_merge' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.activity.commits.last
        assert_equal [], bzr.activity.commit_tokens(after: last_commit.token)
      end
    end

    it 'must test_commit_tokens_trunk_only_false' do
      # Funny business with commit ordering has been fixed by BzrXmlParser.
      # Now we always see branch commits before merge commit.
      with_bzr_repository('bzr_with_branch') do |bzr|
        expected = ['test@example.com-20090206214301-s93cethy9atcqu9h',
                    'test@example.com-20090206214451-lzjngefdyw3vmgms',
                    'test@example.com-20090206214350-rqhdpz92l11eoq2t', # branch commit
                    'test@example.com-20090206214515-21lkfj3dbocao5pr']  # merge commit
        assert_equal bzr.activity.commit_tokens, expected
      end
    end

    it 'must test_commit_tokens_trunk_only_true' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        expected = ['test@example.com-20090206214301-s93cethy9atcqu9h',
                    'test@example.com-20090206214451-lzjngefdyw3vmgms',
                    'test@example.com-20090206214515-21lkfj3dbocao5pr']  # merge commit
        assert_equal bzr.activity.commit_tokens(trunk_only: true), expected
      end
    end

    it 'must test_nested_branches_commit_tokens_trunk_only_false' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        expected = ['obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
                    'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
                    'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
                    'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
                    'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
                    'obnox@samba.org-20090204004942-73rnw0izen42f154',
                    'test@example.com-20110803170302-fz4mbr89n8f5agha',
                    'test@example.com-20110803170341-v1icvy05b430t68l',
                    'test@example.com-20110803170504-z7xz5uxj02e5x3z6',
                    'test@example.com-20110803170522-asv6i9z6m22jc8zz',
                    'test@example.com-20110803170648-o0xcbni7lwp97azj',
                    'test@example.com-20110803170818-v44umypquqg8migo']
        assert_equal bzr.activity.commit_tokens, expected
      end
    end

    it 'must test_nested_branches_commit_tokens_trunk_only_true' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        expected = ['obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
                    'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
                    'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
                    'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
                    'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
                    'obnox@samba.org-20090204004942-73rnw0izen42f154',
                    'test@example.com-20110803170818-v44umypquqg8migo']
        assert_equal bzr.activity.commit_tokens(trunk_only: true), expected
      end
    end

    it 'must test_commits_trunk_only_false' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        expected = ['test@example.com-20090206214301-s93cethy9atcqu9h',
                    'test@example.com-20090206214451-lzjngefdyw3vmgms',
                    'test@example.com-20090206214350-rqhdpz92l11eoq2t', # branch commit
                    'test@example.com-20090206214515-21lkfj3dbocao5pr']  # merge commit

        assert_equal bzr.activity.commits.map(&:token), expected
      end
    end

    it 'must test_commits_trunk_only_true' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        expected = ['test@example.com-20090206214301-s93cethy9atcqu9h',
                    'test@example.com-20090206214451-lzjngefdyw3vmgms',
                    'test@example.com-20090206214515-21lkfj3dbocao5pr']  # merge commit
        assert_equal bzr.activity.commits(trunk_only: true).map(&:token), expected
      end
    end

    it 'must test_commits_after_merge' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.activity.commits.last
        assert_predicate bzr.activity.commits(after: last_commit.token), :empty?
      end
    end

    it 'must test_commits_after_nested_merge' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.activity.commits.last
        assert_predicate bzr.activity.commits(after: last_commit.token), :empty?
      end
    end

    it 'must test_nested_branches_commits_trunk_only_false' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        expected = ['obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
                    'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
                    'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
                    'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
                    'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
                    'obnox@samba.org-20090204004942-73rnw0izen42f154',
                    'test@example.com-20110803170302-fz4mbr89n8f5agha',
                    'test@example.com-20110803170341-v1icvy05b430t68l',
                    'test@example.com-20110803170504-z7xz5uxj02e5x3z6',
                    'test@example.com-20110803170522-asv6i9z6m22jc8zz',
                    'test@example.com-20110803170648-o0xcbni7lwp97azj',
                    'test@example.com-20110803170818-v44umypquqg8migo']
        assert_equal bzr.activity.commits.map(&:token), expected
      end
    end

    it 'must test_nested_branches_commits_trunk_only_true' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        expected = ['obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
                    'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
                    'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
                    'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
                    'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
                    'obnox@samba.org-20090204004942-73rnw0izen42f154',
                    'test@example.com-20110803170818-v44umypquqg8migo']
        assert_equal bzr.activity.commits(trunk_only: true).map(&:token), expected
      end
    end

    it 'must test_commits' do
      with_bzr_repository('bzr') do |bzr|
        assert_equal bzr.activity.commits.collect(&:token), revision_ids
        assert_equal bzr.activity.commits(after: revision_ids[5]).collect(&:token), revision_ids[6..6]
        assert_equal bzr.activity.commits(after: revision_ids.last).collect(&:token), []

        # Check that the diffs are not populated
        assert_equal bzr.activity.commits.first.diffs, []
      end
    end

    it 'must test_each_commit' do
      with_bzr_repository('bzr') do |bzr|
        commits = []
        bzr.activity.each_commit do |c|
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

        # Make sure we cleaned up after ourselves
        assert !FileTest.exist?(bzr.activity.log_filename)

        # Verify that we got the commits in forward chronological order
        assert_equal commits.collect(&:token), revision_ids
      end
    end

    it 'must test_each_commit_trunk_only_false' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        commits = []
        bzr.activity.each_commit { |c| commits << c }
        expected = ['test@example.com-20090206214301-s93cethy9atcqu9h',
                    'test@example.com-20090206214451-lzjngefdyw3vmgms',
                    'test@example.com-20090206214350-rqhdpz92l11eoq2t', # branch commit
                    'test@example.com-20090206214515-21lkfj3dbocao5pr'] # merge commit]
        assert_equal commits.map(&:token), expected
      end
    end

    it 'must test_each_commit_trunk_only_true' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        commits = []
        bzr.activity.each_commit(trunk_only: true) { |c| commits << c }
        expected = [
          'test@example.com-20090206214301-s93cethy9atcqu9h',
          'test@example.com-20090206214451-lzjngefdyw3vmgms',
          'test@example.com-20090206214515-21lkfj3dbocao5pr' # merge commit
          # 'test@example.com-20090206214350-rqhdpz92l11eoq2t' # branch commit -- after merge!
        ]
        assert_equal commits.map(&:token), expected
      end
    end

    it 'must test_each_commit_after_merge' do
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.activity.commits.last

        commits = []
        bzr.activity.each_commit(after: last_commit.token) { |c| commits << c }
        assert_equal commits, []
      end
    end

    it 'must test_each_commit_after_nested_merge_at_tip' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.activity.commits.last

        commits = []
        bzr.activity.each_commit(after: last_commit.token) { |c| commits << c }
        assert_equal commits, []
      end
    end

    it 'must test_each_commit_after_nested_merge_not_at_tip' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.activity.commits.last
        next_to_last_commit = bzr.activity.commits[-2]

        yielded_commits = []
        bzr.activity.each_commit(after: next_to_last_commit.token) { |c| yielded_commits << c }
        assert_equal yielded_commits.map(&:token), [last_commit.token]
      end
    end

    it 'must test_nested_branches_each_commit_trunk_only_false' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        commits = []
        bzr.activity.each_commit { |c| commits << c }
        expected = ['obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
                    'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
                    'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
                    'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
                    'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
                    'obnox@samba.org-20090204004942-73rnw0izen42f154',
                    'test@example.com-20110803170302-fz4mbr89n8f5agha',
                    'test@example.com-20110803170341-v1icvy05b430t68l',
                    'test@example.com-20110803170504-z7xz5uxj02e5x3z6',
                    'test@example.com-20110803170522-asv6i9z6m22jc8zz',
                    'test@example.com-20110803170648-o0xcbni7lwp97azj',
                    'test@example.com-20110803170818-v44umypquqg8migo']
        assert_equal commits.map(&:token), expected
      end
    end

    it 'must test_nested_branches_each_commit_trunk_only_true' do
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        commits = []
        bzr.activity.each_commit(trunk_only: true) { |c| commits << c }
        expected = ['obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
                    'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
                    'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
                    'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
                    'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
                    'obnox@samba.org-20090204004942-73rnw0izen42f154',
                    'test@example.com-20110803170818-v44umypquqg8migo']
        assert_equal commits.map(&:token), expected
      end
    end

    # This bzr repository contains the following tree structure
    #    /foo/
    #    /foo/helloworld.c
    #    /bar/
    # Ohloh doesn't care about directories, so only /foo/helloworld.c should be reported.
    it 'must test_each_commit_excludes_directories' do
      with_bzr_repository('bzr_with_subdirectories') do |bzr|
        commits = []
        bzr.activity.each_commit do |c|
          commits << c
        end
        assert_equal commits.size, 1
        assert_equal commits.first.diffs.size, 1
        assert_equal commits.first.diffs.first.path, 'foo/helloworld.c'
      end
    end

    # Verfies OTWO-344
    it 'must test_commit_tokens_with_colon_character' do
      with_bzr_repository('bzr_colon') do |bzr|
        assert_equal bzr.activity.commit_tokens, ['svn-v4:364a429a-ab12-11de-804f-e3d9c25ff3d2::0']
      end
    end

    it 'must test_committer_and_author_name' do
      with_bzr_repository('bzr_with_authors') do |bzr|
        commits = []
        bzr.activity.each_commit do |c|
          commits << c
        end
        assert_equal commits.size, 3

        assert_equal commits[0].message, 'Initial.'
        assert_equal commits[0].committer_name, 'Abhay Mujumdar'
        assert_nil commits[0].author_name
        assert_nil commits[0].author_email

        assert_equal commits[1].message, 'Updated.'
        assert_equal commits[1].committer_name, 'Abhay Mujumdar'
        assert_equal commits[1].author_name, 'John Doe'
        assert_equal commits[1].author_email, 'johndoe@example.com'

        # When there are multiple authors, first one is captured.
        assert_equal commits[2].message, 'Updated by two authors.'
        assert_equal commits[2].committer_name, 'test'
        assert_equal commits[2].author_name, 'John Doe'
        assert_equal commits[2].author_email, 'johndoe@example.com'
      end
    end

    # Bzr converts invalid utf-8 characters into valid format before commit.
    # So no utf-8 encoding issues are seen in ruby when dealing with Bzr.
    it 'must test_commits_encoding' do
      with_bzr_repository('bzr_with_invalid_encoding') do |bzr|
        assert bzr.activity.commits
      end
    end

    protected

    def revision_ids
      ['obnox@samba.org-20090204002342-5r0q4gejk69rk6uv', # 1
       'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0', # 2
       'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1', # 3
       'obnox@samba.org-20090204002518-yb0x153oa6mhoodu', # 4
       'obnox@samba.org-20090204002540-gmana8tk5f9gboq9', # 5
       'obnox@samba.org-20090204004942-73rnw0izen42f154', # 6
       'test@example.com-20111222183733-y91if5npo3pe8ifs'] # 7
    end
  end

  it 'must get the tags correctly' do
    with_bzr_repository('bzr') do |bzr|
      time1 = Time.parse('2009-02-04 00:25:40 +0000')
      time2 = Time.parse('2011-12-22 18:37:33 +0000')
      time3 = Time.parse('2009-02-04 00:24:22 +0000')

      assert_equal bzr.activity.tags, [['v1.0.0', '5', time1],
                                       ['v2.0.0', '7', time2], ['v 3.0.0', '2', time3]]
    end
  end
end
