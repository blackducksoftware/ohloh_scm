require_relative '../test_helper'

module OhlohScm::Adapters
	class BzrPullTest < OhlohScm::Test

		def test_pull
			with_bzr_repository('bzr') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|

					dest = BzrAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					assert_equal src.log, dest.log

					# Commit some new code on the original and pull again
					src.run "cd '#{src.url}' && touch foo && bzr add foo && bzr whoami 'test <test@example.com>' && bzr commit -m test"
					assert_equal "test", src.commits.last.message
					assert_equal "test", src.commits.last.committer_name
					assert_equal "test@example.com", src.commits.last.committer_email

					dest.pull(src)
					assert_equal src.log, dest.log
				end
			end
		end

	end
end
