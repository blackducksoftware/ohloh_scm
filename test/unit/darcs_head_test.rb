require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Adapters
	class DarcsHeadTest < OhlohScm::Test

		def test_head_and_parents
			with_darcs_repository('darcs') do |darcs|
				assert_equal '1007b5ad4831769283213d47e1fd5f6d30ac97f0', darcs.head_token
				assert_equal '1007b5ad4831769283213d47e1fd5f6d30ac97f0', darcs.head.token
				assert darcs.head.diffs.any? # diffs should be populated

				assert_equal 'bd7e455d648b784ce4be2db26a4e62dfe734dd66', darcs.parents(darcs.head).first.token
				assert darcs.parents(darcs.head).first.diffs.any?
			end
		end

	end
end
