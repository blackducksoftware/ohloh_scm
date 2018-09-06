require_relative '../test_helper'

module OhlohScm::Adapters
	class HgCommitsTest < OhlohScm::Test

		def test_commit_count
			with_hg_repository('hg') do |hg|
				assert_equal 5, hg.commit_count
				assert_equal 3, hg.commit_count(:after => 'b14fa4692f949940bd1e28da6fb4617de2615484')
				assert_equal 0, hg.commit_count(:after => '655f04cf6ad708ab58c7b941672dce09dd369a18')
			end
		end

		def test_commit_count_with_empty_branch
          	with_hg_repository('hg', '') do |hg|
        		assert_equal nil, hg.branch_name
        		assert_equal 5, hg.commit_count
        		assert_equal 3, hg.commit_count(:after => 'b14fa4692f949940bd1e28da6fb4617de2615484')
        		assert_equal 0, hg.commit_count(:after => '655f04cf6ad708ab58c7b941672dce09dd369a18')
      		end
    	end


		def test_commit_tokens
			with_hg_repository('hg') do |hg|
				assert_equal ['01101d8ef3cea7da9ac6e9a226d645f4418f05c9',
											'b14fa4692f949940bd1e28da6fb4617de2615484',
											'468336c6671cbc58237a259d1b7326866afc2817',
                      '75532c1e1f1de55c2271f6fd29d98efbe35397c4',
											'655f04cf6ad708ab58c7b941672dce09dd369a18'], hg.commit_tokens

				assert_equal ['655f04cf6ad708ab58c7b941672dce09dd369a18'],
					hg.commit_tokens(:after => '75532c1e1f1de55c2271f6fd29d98efbe35397c4')

				assert_equal [], hg.commit_tokens(:after => '655f04cf6ad708ab58c7b941672dce09dd369a18')
			end
		end

		def test_commits
			with_hg_repository('hg') do |hg|
				assert_equal ['01101d8ef3cea7da9ac6e9a226d645f4418f05c9',
											'b14fa4692f949940bd1e28da6fb4617de2615484',
											'468336c6671cbc58237a259d1b7326866afc2817',
                      '75532c1e1f1de55c2271f6fd29d98efbe35397c4',
											'655f04cf6ad708ab58c7b941672dce09dd369a18'], hg.commits.collect { |c| c.token }

				assert_equal ['655f04cf6ad708ab58c7b941672dce09dd369a18'],
					hg.commits(:after => '75532c1e1f1de55c2271f6fd29d98efbe35397c4').collect { |c| c.token }

				# Check that the diffs are not populated
				assert_equal [], hg.commits(:after => '75532c1e1f1de55c2271f6fd29d98efbe35397c4').first.diffs

				assert_equal [], hg.commits(:after => '655f04cf6ad708ab58c7b941672dce09dd369a18')
			end
		end

		def test_commits_with_branch
			with_hg_repository('hg', 'develop') do |hg|
				assert_equal ['01101d8ef3cea7da9ac6e9a226d645f4418f05c9',
											'b14fa4692f949940bd1e28da6fb4617de2615484',
											'468336c6671cbc58237a259d1b7326866afc2817',
                      '75532c1e1f1de55c2271f6fd29d98efbe35397c4',
											'4d54c3f0526a1ec89214a70615a6b1c6129c665c'], hg.commits.collect { |c| c.token }

				assert_equal ['4d54c3f0526a1ec89214a70615a6b1c6129c665c'],
					hg.commits(:after => '75532c1e1f1de55c2271f6fd29d98efbe35397c4').collect { |c| c.token }

				# Check that the diffs are not populated
				assert_equal [], hg.commits(:after => '75532c1e1f1de55c2271f6fd29d98efbe35397c4').first.diffs

				assert_equal [], hg.commits(:after => '4d54c3f0526a1ec89214a70615a6b1c6129c665c')
			end
		end

		def test_trunk_only_commit_count
			with_hg_repository('hg_dupe_delete') do |hg|
				assert_equal 4, hg.commit_count(:trunk_only => false)
				assert_equal 3, hg.commit_count(:trunk_only => true)
			end
		end

		def test_trunk_only_commit_tokens
			with_hg_repository('hg_dupe_delete') do |hg|
				assert_equal ['73e93f57224e3fd828cf014644db8eec5013cd6b',
											'732345b1d5f4076498132fd4b965b1fec0108a50',
											'525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
											'72fe74d643bdcb30b00da3b58796c50f221017d0'],
					hg.commit_tokens(:trunk_only => false)

				assert_equal ['73e93f57224e3fd828cf014644db8eec5013cd6b',
											'732345b1d5f4076498132fd4b965b1fec0108a50',
											# '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
											'72fe74d643bdcb30b00da3b58796c50f221017d0'],
					hg.commit_tokens(:trunk_only => true)
			end
		end

		def test_trunk_only_commit_tokens_using_after
			with_hg_repository('hg_dupe_delete') do |hg|
				assert_equal ['732345b1d5f4076498132fd4b965b1fec0108a50',
											'525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
											'72fe74d643bdcb30b00da3b58796c50f221017d0'],
					hg.commit_tokens(
						:after => '73e93f57224e3fd828cf014644db8eec5013cd6b',
						:trunk_only => false)

				assert_equal ['732345b1d5f4076498132fd4b965b1fec0108a50',
											# '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
											'72fe74d643bdcb30b00da3b58796c50f221017d0'],
					hg.commit_tokens(
						:after => '73e93f57224e3fd828cf014644db8eec5013cd6b',
						:trunk_only => true)

				assert_equal [], hg.commit_tokens(
					:after => '72fe74d643bdcb30b00da3b58796c50f221017d0',
					:trunk_only => true)
			end
		end

		def test_trunk_only_commits
			with_hg_repository('hg_dupe_delete') do |hg|
				assert_equal ['73e93f57224e3fd828cf014644db8eec5013cd6b',
											'732345b1d5f4076498132fd4b965b1fec0108a50',
											# '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
											'72fe74d643bdcb30b00da3b58796c50f221017d0'],
					hg.commits(:trunk_only => true).collect { |c| c.token }
			end
		end

		def test_each_commit
			commits = []
			with_hg_repository('hg') do |hg|
				hg.each_commit do |c|
					assert c.token.length == 40
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
				assert !FileTest.exist?(hg.log_filename) # Make sure we cleaned up after ourselves

				# Verify that we got the commits in forward chronological order
				assert_equal ['01101d8ef3cea7da9ac6e9a226d645f4418f05c9',
											'b14fa4692f949940bd1e28da6fb4617de2615484',
											'468336c6671cbc58237a259d1b7326866afc2817',
											'75532c1e1f1de55c2271f6fd29d98efbe35397c4',
                      '655f04cf6ad708ab58c7b941672dce09dd369a18'], commits.collect { |c| c.token }
			end
		end

    def test_each_commit_for_branch
      commits = []

			with_hg_repository('hg', 'develop') do |hg|
        commits = hg.each_commit
      end

      assert_equal ['01101d8ef3cea7da9ac6e9a226d645f4418f05c9',
                    'b14fa4692f949940bd1e28da6fb4617de2615484',
                    '468336c6671cbc58237a259d1b7326866afc2817',
                    '75532c1e1f1de55c2271f6fd29d98efbe35397c4',
                    '4d54c3f0526a1ec89214a70615a6b1c6129c665c'], commits.collect { |c| c.token }
    end


		def test_each_commit_after
			commits = []
			with_hg_repository('hg') do |hg|
				hg.each_commit(:after => '468336c6671cbc58237a259d1b7326866afc2817') do |c|
					commits << c
				end
				assert_equal ['75532c1e1f1de55c2271f6fd29d98efbe35397c4',
											'655f04cf6ad708ab58c7b941672dce09dd369a18'], commits.collect { |c| c.token }
			end
		end

    def test_commits_encoding
      with_hg_repository('hg_with_invalid_encoding') do |hg|
        assert_nothing_raised do
          hg.commits
        end
      end
    end

    def test_verbose_commit_encoding
      with_hg_repository('hg_with_invalid_encoding') do |hg|
        assert_nothing_raised do
          hg.verbose_commit('51ea5277ca27')
        end
      end
    end
	end
end

