require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class DarcsHeadTest < Scm::Test

		def test_head_and_parents
			with_darcs_repository('darcs') do |darcs|
				assert_equal '75532c1e1f1d', darcs.head_token
				assert_equal '75532c1e1f1de55c2271f6fd29d98efbe35397c4', darcs.head.token
				assert darcs.head.diffs.any? # diffs should be populated

				assert_equal '468336c6671cbc58237a259d1b7326866afc2817', darcs.parents(darcs.head).first.token
				assert darcs.parents(darcs.head).first.diffs.any?
			end
		end

	end
end
