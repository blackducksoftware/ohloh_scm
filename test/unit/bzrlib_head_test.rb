require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class BzrBzrlibHeadTest < Scm::Test

		def test_head_and_parents
			with_bzrlib_repository('bzr') do |bzr|
				assert_equal 'obnox@samba.org-20090204004942-73rnw0izen42f154', bzr.head_token
				assert_equal 'obnox@samba.org-20090204004942-73rnw0izen42f154', bzr.head.token
				assert bzr.head.diffs.any? # diffs should be populated

				assert_equal 'obnox@samba.org-20090204002540-gmana8tk5f9gboq9', bzr.parents(bzr.head).first.token
				assert bzr.parents(bzr.head).first.diffs.any?
			end
		end

	end
end
