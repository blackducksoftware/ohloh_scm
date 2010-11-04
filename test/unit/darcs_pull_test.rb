require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class DarcsPullTest < Scm::Test

		def test_pull
			with_darcs_repository('darcs') do |src|
				Scm::ScratchDir.new do |dest_dir|

					dest = DarcsAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					assert_equal src.log, dest.log

					# Commit some new code on the original and pull again
					src.run "cd '#{src.url}' && touch foo && darcs add foo && darcs commit -u test -m test"
					assert_equal "test\n", src.commits.last.message

					dest.pull(src)
					assert_equal src.log, dest.log
				end
			end
		end

	end
end
