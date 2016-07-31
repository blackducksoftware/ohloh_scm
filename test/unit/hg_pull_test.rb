require_relative '../test_helper'

module OhlohScm::Adapters
	class HgPullTest < OhlohScm::Test

		def test_pull
			with_hg_repository('hg') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|

					dest = HgAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					assert_equal src.log, dest.log

					# Commit some new code on the original and pull again
					src.run "cd '#{src.url}' && touch foo && hg add foo && hg commit -u test -m test"
					assert_equal "test\n", src.commits.last.message

					dest.pull(src)
					assert_equal src.log, dest.log
				end
			end
		end

	end
end
