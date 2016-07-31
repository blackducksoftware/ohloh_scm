require_relative '../test_helper'

module OhlohScm::Adapters
	class SvnConvertTest < OhlohScm::Test
		def test_basic_convert
			with_svn_repository('svn') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|
					dest = GitAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					dest_commits = dest.commits
					src.commits.each_with_index do |c, i|
						# Because Subversion does not track authors (only committers),
						# the Subversion committer becomes the Git author.
						assert_equal c.committer_name, dest_commits[i].author_name
						assert_equal c.committer_date.round, dest_commits[i].author_date

						# The svn-to-git conversion process loses the trailing \n for single-line messages
						assert_equal c.message.strip, dest_commits[i].message.strip
					end
				end
			end
		end
	end
end
