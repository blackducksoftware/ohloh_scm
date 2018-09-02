require_relative '../test_helper'

module OhlohScm::Adapters
	class SvnHeadTest < OhlohScm::Test

		def test_head_and_parents
			with_svn_repository('svn') do |svn|
				assert_equal 5, svn.head_token
				assert_equal 5, svn.head.token
				assert svn.head.diffs.any?

				assert_equal 4, svn.parents(svn.head).first.token
				assert svn.parents(svn.head).first.diffs.any?
			end
		end
	end
end

