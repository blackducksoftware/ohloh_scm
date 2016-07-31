require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Adapters
	class DarcsCommitsTest < OhlohScm::Test

		def test_commit
			with_darcs_repository('darcs') do |darcs|
				assert_equal 2, darcs.commit_count
				assert_equal 1, darcs.commit_count(:after => 'bd7e455d648b784ce4be2db26a4e62dfe734dd66')
				assert_equal 0, darcs.commit_count(:after => '1007b5ad4831769283213d47e1fd5f6d30ac97f0')
				assert_equal ['bd7e455d648b784ce4be2db26a4e62dfe734dd66', '1007b5ad4831769283213d47e1fd5f6d30ac97f0'], darcs.commit_tokens
				assert_equal ['1007b5ad4831769283213d47e1fd5f6d30ac97f0'], darcs.commit_tokens(:after => 'bd7e455d648b784ce4be2db26a4e62dfe734dd66')
				assert_equal [], darcs.commit_tokens(:after => '1007b5ad4831769283213d47e1fd5f6d30ac97f0')
				assert_equal ['bd7e455d648b784ce4be2db26a4e62dfe734dd66',
											'1007b5ad4831769283213d47e1fd5f6d30ac97f0'], darcs.commits.collect { |c| c.token }
				assert_equal ['1007b5ad4831769283213d47e1fd5f6d30ac97f0'], darcs.commits(:after => 'bd7e455d648b784ce4be2db26a4e62dfe734dd66').collect { |c| c.token }
				# Check that the diffs are not populated
				assert_equal [], darcs.commits(:after => 'bd7e455d648b784ce4be2db26a4e62dfe734dd66').first.diffs
				assert_equal [], darcs.commits(:after => '1007b5ad4831769283213d47e1fd5f6d30ac97f0')
			end
		end

		def test_each_commit
			commits = []
			with_darcs_repository('darcs') do |darcs|
				darcs.each_commit do |c|
					assert c.author_name
					assert c.author_date.is_a?(Time)
					assert c.diffs.any?
					# Check that the diffs are populated
					c.diffs.each do |d|
						assert d.action =~ /^[MAD]$/
						assert d.path.length > 0
					end
					commits << c
				end
				assert !FileTest.exist?(darcs.log_filename) # Make sure we cleaned up after ourselves

				# Verify that we got the commits in forward chronological order
				assert_equal ['bd7e455d648b784ce4be2db26a4e62dfe734dd66',
											'1007b5ad4831769283213d47e1fd5f6d30ac97f0'], commits.map {|c| c.token}
			end
		end
	end
end
