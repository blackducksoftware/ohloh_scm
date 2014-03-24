require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	# Repository darcs_walk has the following structure:
	#
	#    A -> B -> C -> D -> E
	#
	class DarcsRevListTest < Scm::Test

		def test_rev_list
			with_darcs_repository('darcs_walk') do |darcs|
				# Full history to a commit
				assert_equal ["A"],                 darcs.commit_tokens(nil, "A")
				assert_equal ["A","B"],             darcs.commit_tokens(nil, "B")
				assert_equal ["A","B","C","D","E"], darcs.commit_tokens(nil, "E")
				assert_equal ["A","B","C","D","E"], darcs.commit_tokens(nil, nil)

				# # Limited history from one commit to another
				assert_equal [],            darcs.commit_tokens("A", "A")
				assert_equal ["B"],         darcs.commit_tokens("A", "B")
				assert_equal ["B","C","D"], darcs.commit_tokens("A", "D")
			end
		end
	end
end
