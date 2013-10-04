require 'digest/sha1'

NULL_SHA1 = '0000000000000000000000000000000000000000' unless defined?(NULL_SHA1)

module Scm::Adapters
	class AbstractAdapter

		# This file provides SHA1 computation helpers for source control systems that
		# don't have them natively (that is, everyone except Git!).
		# So GitAdapter doesn't use this code, but others can us it to compute SHA1s
		# that match those generated natively by Git.

		def compute_sha1(blob)
			blob.to_s == '' ? NULL_SHA1 : SHA1.sha1("blob #{blob.length}\0#{blob}").to_s
		end

		# Populates the SHA1 values for each diff in a commit.
		def populate_commit_sha1s!(commit)
			if commit.diffs
				commit.diffs.each do |diff|
					populate_diff_sha1s!(commit, diff)
				end
			end
			commit
		end

		# Populates the SHA1 values for a single diff.
		def populate_diff_sha1s!(commit, diff)
			diff.sha1 =
				case diff.action
				when 'D'
					NULL_SHA1
				else
					compute_sha1(cat_file(commit, diff))
				end

			diff.parent_sha1 =
				case diff.action
				when 'A'
					NULL_SHA1
				else
					compute_sha1(cat_file_parent(commit, diff))
				end

			diff
		end
	end
end
