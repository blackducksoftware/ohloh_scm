require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class DarcsCommitsTest < Scm::Test

		def test_commit
			with_darcs_repository('darcs') do |darcs|
				assert_equal 2, darcs.commit_count
				assert_equal 1, darcs.commit_count('add helloworld.c')
				assert_equal 0, darcs.commit_count('remove helloworld.c')
				assert_equal ['add helloworld.c', 'remove helloworld.c'], darcs.commit_tokens
				assert_equal ['remove helloworld.c'], darcs.commit_tokens('add helloworld.c')
				assert_equal [], darcs.commit_tokens('remove helloworld.c')
				assert_equal ['add helloworld.c',
											'remove helloworld.c'], darcs.commits.collect { |c| c.token }
				assert_equal ['remove helloworld.c'], darcs.commits('add helloworld.c').collect { |c| c.token }
				# Check that the diffs are not populated
				assert_equal [], darcs.commits('add helloworld.c').first.diffs
				assert_equal [], darcs.commits('remove helloworld.c')
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
				assert_equal ['add helloworld.c',
											'remove helloworld.c'], commits.map {|c| c.token}
			end
		end
	end
end
