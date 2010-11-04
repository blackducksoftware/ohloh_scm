require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class DarcsHeadTest < Scm::Test

		def test_head_and_parents
			with_darcs_repository('darcs') do |darcs|
				assert_equal 'remove helloworld.c', darcs.head_token
				assert_equal 'remove helloworld.c', darcs.head.token
				assert darcs.head.diffs.any? # diffs should be populated

				assert_equal 'add helloworld.c', darcs.parents(darcs.head).first.token
				assert darcs.parents(darcs.head).first.diffs.any?
			end
		end

	end
end
