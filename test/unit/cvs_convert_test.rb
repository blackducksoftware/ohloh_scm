require_relative '../test_helper'

module OhlohScm::Adapters
	class CvsConvertTest < OhlohScm::Test

		def test_basic_convert
			with_cvs_repository('cvs', 'simple') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|
					dest = GitAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					dest_commits = dest.commits
					src.commits.each_with_index do |c, i|
						# Because CVS does not track authors (only committers),
						# the CVS committer becomes the Git author.
						assert_equal c.committer_date, dest_commits[i].author_date
						assert_equal c.committer_name, dest_commits[i].author_name

						# Depending upon version of Git used, we may or may not have a trailing \n.
						# We don't really care, so just compare the stripped versions.
						assert_equal c.message.strip, dest_commits[i].message.strip
					end
				end
			end
		end
	end
end
