require_relative '../test_helper'

module OhlohScm::Adapters
	class BzrCommitsTest < OhlohScm::Test

		def test_commit_count
			with_bzr_repository('bzr') do |bzr|
				assert_equal 7, bzr.commit_count
				assert_equal 6, bzr.commit_count(:after => revision_ids.first)
				assert_equal 1, bzr.commit_count(:after => revision_ids[5])
				assert_equal 0, bzr.commit_count(:after => revision_ids.last)
			end
		end

		def test_commit_count_with_branches
			with_bzr_repository('bzr_with_branch') do |bzr|
				# Only 3 commits are on main line... make sure we catch the branch commit as well
				assert_equal 4, bzr.commit_count
			end
		end

    def test_commit_count_after_merge
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.commits.last
        assert_equal 0, bzr.commit_count(:trunk_only => false, :after => last_commit.token)
      end
    end

		def test_commit_count_trunk_only
			with_bzr_repository('bzr_with_branch') do |bzr|
				# Only 3 commits are on main line
				assert_equal 3, bzr.commit_count(:trunk_only => true)
			end
		end

		def test_commit_tokens_after
			with_bzr_repository('bzr') do |bzr|
				assert_equal revision_ids, bzr.commit_tokens
				assert_equal revision_ids[1..6], bzr.commit_tokens(:after => revision_ids.first)
				assert_equal revision_ids[6..6], bzr.commit_tokens(:after => revision_ids[5])
				assert_equal [], bzr.commit_tokens(:after => revision_ids.last)
			end
		end

    def test_commit_tokens_after_merge
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.commits.last
        assert_equal [], bzr.commit_tokens(:trunk_only => false, :after => last_commit.token)
      end
    end

    def test_commit_tokens_after_nested_merge
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.commits.last
        assert_equal [], bzr.commit_tokens(:trunk_only => false, :after => last_commit.token)
      end
    end

		def test_commit_tokens_trunk_only_false
			# Funny business with commit ordering has been fixed by BzrXmlParser.
      # Now we always see branch commits before merge commit.
			with_bzr_repository('bzr_with_branch') do |bzr|
				assert_equal [
					'test@example.com-20090206214301-s93cethy9atcqu9h',
					'test@example.com-20090206214451-lzjngefdyw3vmgms',
					'test@example.com-20090206214350-rqhdpz92l11eoq2t', # branch commit
					'test@example.com-20090206214515-21lkfj3dbocao5pr'  # merge commit
				], bzr.commit_tokens(:trunk_only => false)
			end
		end

		def test_commit_tokens_trunk_only_true
			with_bzr_repository('bzr_with_branch') do |bzr|
				assert_equal [
					'test@example.com-20090206214301-s93cethy9atcqu9h',
					'test@example.com-20090206214451-lzjngefdyw3vmgms',
					'test@example.com-20090206214515-21lkfj3dbocao5pr'  # merge commit
				], bzr.commit_tokens(:trunk_only => true)
			end
		end

    def test_nested_branches_commit_tokens_trunk_only_false
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        assert_equal [
          'obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
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
          'test@example.com-20110803170818-v44umypquqg8migo'
        ], bzr.commit_tokens(:trunk_only => false)
      end
    end

    def test_nested_branches_commit_tokens_trunk_only_true
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        assert_equal [
          'obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
          'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
          'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
          'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
          'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
          'obnox@samba.org-20090204004942-73rnw0izen42f154',
          'test@example.com-20110803170818-v44umypquqg8migo'
        ], bzr.commit_tokens(:trunk_only => true)
      end
    end

		def test_commits_trunk_only_false
			with_bzr_repository('bzr_with_branch') do |bzr|
				assert_equal [
					'test@example.com-20090206214301-s93cethy9atcqu9h',
					'test@example.com-20090206214451-lzjngefdyw3vmgms',
					'test@example.com-20090206214350-rqhdpz92l11eoq2t', # branch commit
					'test@example.com-20090206214515-21lkfj3dbocao5pr'  # merge commit
				], bzr.commits(:trunk_only => false).map { |c| c.token }
			end
		end

		def test_commits_trunk_only_true
			with_bzr_repository('bzr_with_branch') do |bzr|
				assert_equal [
					'test@example.com-20090206214301-s93cethy9atcqu9h',
					'test@example.com-20090206214451-lzjngefdyw3vmgms',
					'test@example.com-20090206214515-21lkfj3dbocao5pr'  # merge commit
				], bzr.commits(:trunk_only => true).map { |c| c.token }
			end
		end

    def test_commits_after_merge
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.commits.last
        assert_equal [], bzr.commits(:trunk_only => false, :after => last_commit.token)
      end
    end

    def test_commits_after_nested_merge
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.commits.last
        assert_equal [], bzr.commits(:trunk_only => false, :after => last_commit.token)
      end
    end

    def test_nested_branches_commits_trunk_only_false
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        assert_equal [
          'obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
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
          'test@example.com-20110803170818-v44umypquqg8migo'
        ], bzr.commits(:trunk_only => false).map { |c| c.token }
      end
    end

    def test_nested_branches_commits_trunk_only_true
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        assert_equal [
          'obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
          'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
          'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
          'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
          'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
          'obnox@samba.org-20090204004942-73rnw0izen42f154',
          'test@example.com-20110803170818-v44umypquqg8migo'
        ], bzr.commits(:trunk_only => true).map { |c| c.token }
      end
    end

		def test_commits
			with_bzr_repository('bzr') do |bzr|
				assert_equal revision_ids, bzr.commits.collect { |c| c.token }
				assert_equal revision_ids[6..6], bzr.commits(:after => revision_ids[5]).collect { |c| c.token }
				assert_equal [], bzr.commits(:after => revision_ids.last).collect { |c| c.token }

				# Check that the diffs are not populated
				assert_equal [], bzr.commits.first.diffs
			end
		end

		def test_each_commit
			with_bzr_repository('bzr') do |bzr|
				commits = []
				bzr.each_commit do |c|
					assert c.committer_name
					assert c.committer_date.is_a?(Time)
					assert c.message.length > 0
					assert c.diffs.any?
					# Check that the diffs are populated
					c.diffs.each do |d|
						assert d.action =~ /^[MAD]$/
						assert d.path.length > 0
					end
					commits << c
				end

				# Make sure we cleaned up after ourselves
				assert !FileTest.exist?(bzr.log_filename)

				# Verify that we got the commits in forward chronological order
				assert_equal revision_ids, commits.collect{ |c| c.token }
			end
		end

		def test_each_commit_trunk_only_false
			with_bzr_repository('bzr_with_branch') do |bzr|
				commits = []
				bzr.each_commit(:trunk_only => false) { |c| commits << c }
				assert_equal [
					'test@example.com-20090206214301-s93cethy9atcqu9h',
					'test@example.com-20090206214451-lzjngefdyw3vmgms',
					'test@example.com-20090206214350-rqhdpz92l11eoq2t', # branch commit
					'test@example.com-20090206214515-21lkfj3dbocao5pr'  # merge commit
				], commits.map { |c| c.token }
			end
		end

		def test_each_commit_trunk_only_true
			with_bzr_repository('bzr_with_branch') do |bzr|
				commits = []
				bzr.each_commit(:trunk_only => true) { |c| commits << c }
				assert_equal [
					'test@example.com-20090206214301-s93cethy9atcqu9h',
					'test@example.com-20090206214451-lzjngefdyw3vmgms',
					'test@example.com-20090206214515-21lkfj3dbocao5pr'   # merge commit
					# 'test@example.com-20090206214350-rqhdpz92l11eoq2t' # branch commit -- after merge!
				], commits.map { |c| c.token }
			end
		end

    def test_each_commit_after_merge
      with_bzr_repository('bzr_with_branch') do |bzr|
        last_commit = bzr.commits.last

        commits = []
        bzr.each_commit(:trunk_only => false, :after => last_commit.token) { |c| commits << c }
        assert_equal [], commits
      end
    end

    def test_each_commit_after_nested_merge_at_tip
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.commits.last

        commits = []
        bzr.each_commit(:trunk_only => false, :after => last_commit.token) { |c| commits << c }
        assert_equal [], commits
      end
    end

    def test_each_commit_after_nested_merge_not_at_tip
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        last_commit = bzr.commits.last
        next_to_last_commit = bzr.commits[-2]

        yielded_commits = []
        bzr.each_commit(:trunk_only => false, :after => next_to_last_commit.token) { |c| yielded_commits << c }
        assert_equal [last_commit.token], yielded_commits.map(&:token)
      end
    end

    def test_nested_branches_each_commit_trunk_only_false
      with_bzr_repository('bzr_with_nested_branches') do |bzr|
        commits = []
        bzr.each_commit(:trunk_only => false) { |c| commits << c}
        assert_equal [
          'obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
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
          'test@example.com-20110803170818-v44umypquqg8migo'
        ], commits.map { |c| c.token }
      end
    end

		def test_nested_branches_each_commit_trunk_only_true
			with_bzr_repository('bzr_with_nested_branches') do |bzr|
				commits = []
				bzr.each_commit(:trunk_only => true) { |c| commits << c }
				assert_equal [
          'obnox@samba.org-20090204002342-5r0q4gejk69rk6uv',
          'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0',
          'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1',
          'obnox@samba.org-20090204002518-yb0x153oa6mhoodu',
          'obnox@samba.org-20090204002540-gmana8tk5f9gboq9',
          'obnox@samba.org-20090204004942-73rnw0izen42f154',
          'test@example.com-20110803170818-v44umypquqg8migo'
				], commits.map { |c| c.token }
			end
		end

		# This bzr repository contains the following tree structure
		#    /foo/
		#    /foo/helloworld.c
		#    /bar/
		# Ohloh doesn't care about directories, so only /foo/helloworld.c should be reported.
		def test_each_commit_excludes_directories
			with_bzr_repository('bzr_with_subdirectories') do |bzr|
				commits = []
				bzr.each_commit do |c|
					commits << c
				end
				assert_equal 1, commits.size
				assert_equal 1, commits.first.diffs.size
				assert_equal 'foo/helloworld.c', commits.first.diffs.first.path
			end
		end

		# Verfies OTWO-344
		def test_commit_tokens_with_colon_character
			with_bzr_repository('bzr_colon') do |bzr|
				assert_equal ['svn-v4:364a429a-ab12-11de-804f-e3d9c25ff3d2::0'], bzr.commit_tokens
			end
		end

    def test_committer_and_author_name
      with_bzr_repository('bzr_with_authors') do |bzr|
        commits = []
        bzr.each_commit do |c|
          commits << c
        end
        assert_equal 3, commits.size

        assert_equal 'Initial.', commits[0].message
        assert_equal 'Abhay Mujumdar', commits[0].committer_name
        assert_equal nil, commits[0].author_name
        assert_equal nil, commits[0].author_email

        assert_equal 'Updated.', commits[1].message
        assert_equal 'Abhay Mujumdar', commits[1].committer_name
        assert_equal 'John Doe', commits[1].author_name
        assert_equal 'johndoe@example.com', commits[1].author_email

        # When there are multiple authors, first one is captured.
        assert_equal 'Updated by two authors.', commits[2].message
        assert_equal 'test', commits[2].committer_name
        assert_equal 'John Doe', commits[2].author_name
        assert_equal 'johndoe@example.com', commits[2].author_email
      end
    end

    # Bzr converts invalid utf-8 characters into valid format before commit.
    # So no utf-8 encoding issues are seen in ruby when dealing with Bzr.
    def test_commits_encoding
      with_bzr_repository('bzr_with_invalid_encoding') do |bzr|
        assert_nothing_raised do
          bzr.commits
        end
      end
    end

		protected

		def revision_ids
			[
				'obnox@samba.org-20090204002342-5r0q4gejk69rk6uv', # 1
				'obnox@samba.org-20090204002422-5ylnq8l4713eqfy0', # 2
				'obnox@samba.org-20090204002453-u70a3ehf3ae9kay1', # 3
				'obnox@samba.org-20090204002518-yb0x153oa6mhoodu', # 4
				'obnox@samba.org-20090204002540-gmana8tk5f9gboq9', # 5
				'obnox@samba.org-20090204004942-73rnw0izen42f154', # 6
        'test@example.com-20111222183733-y91if5npo3pe8ifs', # 7
			]
		end

	end
end

