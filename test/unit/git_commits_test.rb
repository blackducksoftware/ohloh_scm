require_relative '../test_helper'

module OhlohScm::Adapters
	class GitCommitsTest < OhlohScm::Test

		def test_commit_count
			with_git_repository('git') do |git|
				assert_equal 4, git.commit_count
				assert_equal 2, git.commit_count(:after => 'b6e9220c3cabe53a4ed7f32952aeaeb8a822603d')
				assert_equal 0, git.commit_count(:after => '1df547800dcd168e589bb9b26b4039bff3a7f7e4')
			end
		end

		def test_commit_tokens
			with_git_repository('git') do |git|
				assert_equal ['089c527c61235bd0793c49109b5bd34d439848c6',
											'b6e9220c3cabe53a4ed7f32952aeaeb8a822603d',
											'2e9366dd7a786fdb35f211fff1c8ea05c51968b1',
											'1df547800dcd168e589bb9b26b4039bff3a7f7e4'], git.commit_tokens

				assert_equal ['1df547800dcd168e589bb9b26b4039bff3a7f7e4'],
					git.commit_tokens(:after => '2e9366dd7a786fdb35f211fff1c8ea05c51968b1')

				assert_equal [], git.commit_tokens(:after => '1df547800dcd168e589bb9b26b4039bff3a7f7e4')
			end
		end

		def test_commits
			with_git_repository('git') do |git|
				assert_equal ['089c527c61235bd0793c49109b5bd34d439848c6',
											'b6e9220c3cabe53a4ed7f32952aeaeb8a822603d',
											'2e9366dd7a786fdb35f211fff1c8ea05c51968b1',
											'1df547800dcd168e589bb9b26b4039bff3a7f7e4'], git.commits.collect { |c| c.token }

				assert_equal ['1df547800dcd168e589bb9b26b4039bff3a7f7e4'],
					git.commits(:after => '2e9366dd7a786fdb35f211fff1c8ea05c51968b1').collect { |c| c.token }

				assert_equal [], git.commits(:after => '1df547800dcd168e589bb9b26b4039bff3a7f7e4')
			end
		end

    def test_commits_with_branch
      with_git_repository('git', 'develop') do |git|
        assert_equal ['089c527c61235bd0793c49109b5bd34d439848c6',
                      'b6e9220c3cabe53a4ed7f32952aeaeb8a822603d',
                      '2e9366dd7a786fdb35f211fff1c8ea05c51968b1',
                      'b4046b9a80fead62fa949232f2b87b0cb78fffcc'], git.commits.map(&:token)

        assert_equal ['b4046b9a80fead62fa949232f2b87b0cb78fffcc'],
          git.commits(:after => '2e9366dd7a786fdb35f211fff1c8ea05c51968b1').map(&:token)

        assert_equal [], git.commits(:after => 'b4046b9a80fead62fa949232f2b87b0cb78fffcc')
      end
    end

    def test_trunk_only_commit_count
			with_git_repository('git_dupe_delete') do |git|
				assert_equal 4, git.commit_count(:trunk_only => false)
				assert_equal 3, git.commit_count(:trunk_only => true)
			end
		end

		def test_trunk_only_commit_tokens
			with_git_repository('git_dupe_delete') do |git|
				assert_equal ['a0a2b8623941562031a7d7f95d984feb4a2d719c',
                      'ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                      '6126337d2497806528fd8657181d5d4afadd72a4', # On branch
                      '41c4b1044ebffc968d363e5f5e883134e624f846'],
          git.commit_tokens(:trunk_only => false)

				assert_equal ['a0a2b8623941562031a7d7f95d984feb4a2d719c',
                      'ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                      # '6126337d2497806528fd8657181d5d4afadd72a4', # On branch
                      '41c4b1044ebffc968d363e5f5e883134e624f846'],
          git.commit_tokens(:trunk_only => true)
			end
		end

		def test_trunk_only_commit_tokens_using_after
			with_git_repository('git_dupe_delete') do |git|
				assert_equal ['ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                      '41c4b1044ebffc968d363e5f5e883134e624f846'],
				  git.commit_tokens(
            :after => 'a0a2b8623941562031a7d7f95d984feb4a2d719c',
            :trunk_only => true)

				# All trunk commit_tokens, with :after == HEAD
				assert_equal [], git.commit_tokens(
          :after => '41c4b1044ebffc968d363e5f5e883134e624f846',
          :trunk_only => true)
			end
		end

		def test_trunk_only_commits
			with_git_repository('git_dupe_delete') do |git|
				assert_equal ['a0a2b8623941562031a7d7f95d984feb4a2d719c',
                      'ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                      # The following commit is on a branch and should be excluded
                      # '6126337d2497806528fd8657181d5d4afadd72a4',
                      '41c4b1044ebffc968d363e5f5e883134e624f846'],
          git.commits(:trunk_only => true).collect { |c| c.token }
			end
		end

		def test_trunk_only_commits_using_after
			with_git_repository('git_dupe_delete') do |git|
				assert_equal ['ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                      '41c4b1044ebffc968d363e5f5e883134e624f846'],
					git.commits(:after => 'a0a2b8623941562031a7d7f95d984feb4a2d719c',
                      :trunk_only => true).collect { |c| c.token }

				assert_equal [], git.commit_tokens(
          :after => '41c4b1044ebffc968d363e5f5e883134e624f846',
          :trunk_only => true)
			end
    end

    # In rare cases, a merge commit's resulting tree is identical to its first parent's tree.
    # I believe this is a result of developer trickery, and not a common situation.
    #
    # When this happens, `git whatchanged` will omit the changes relative to the first parent,
    # and instead output only the changes relative to the second parent.
    #
    # Our commit parser became confused by this, assuming that these changes relative to the
    # second parent were in fact the missing changes relative to the first.
    #
    # This is bug OTWO-623. This test confirms the fix.
    def test_verbose_commit_with_null_merge
      with_git_repository('git_with_null_merge') do |git|
        c = git.verbose_commit('d3bd0bedbf4b197b2c4eb827e1ec4c35b834482f')
        # This commit's tree is identical to its parent's. Thus it should contain no diffs.
        assert_equal [], c.diffs
      end
    end

    def test_each_commit_with_null_merge
      with_git_repository('git_with_null_merge') do |git|
        git.each_commit do |c|
          assert_equal [], c.diffs if c.token == 'd3bd0bedbf4b197b2c4eb827e1ec4c35b834482f'
        end
      end
    end

    def test_log_encoding
      with_git_repository('git_with_invalid_encoding') do |git|
        assert_equal true, git.log.valid_encoding?
      end
    end

    def test_verbose_commits_valid_encoding
      with_git_repository('git_with_invalid_encoding') do |git|
        assert_equal true,
          git.verbose_commit('8d03f4ea64fcd10966fb3773a212b141ada619e1').message.valid_encoding?
      end
    end

    def test_open_log_file_encoding
      with_git_repository('git_with_invalid_encoding') do |git|
        git.open_log_file do |io|
          assert_equal true, io.read.valid_encoding?
        end
      end
    end

    def test_commit_count_having_tagname_master
      with_git_repository('git_with_master_tag') do |git|
	assert_equal 3, git.commit_count
      end
    end
    
    def test_commit_tokens_having_tagname_master
      with_git_repository('git_with_master_tag') do |git|
	assert_equal ['57b2bd30b7bae970cb3b374a0c05fd6ec3088ebf',
		      '4e95717ac8cff8cdb10d83398d3ac667a2cca341',
                      '34b8a99e6e5dd39bc36893f71e0ab1685668731f'], git.commit_tokens
      end
    end
	end
end
