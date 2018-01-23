require_relative '../test_helper'

module OhlohScm::Adapters
  class SvnConvertTest < OhlohScm::Test
    def test_clone
      with_svn_repository('svn') do |src|
        OhlohScm::ScratchDir.new do |dest_dir|
          dest = SvnToGitAdapter.new(:url => dest_dir).normalize
          assert !dest.exist?

          dest.pull(src)
          assert dest.exist?

          dest_commits = dest.commits
          src.commits.each_with_index do |c, i|
            # Because Subversion does not track authors (only committers),
            # the Subversion committer becomes the Git author.
            assert_equal c.committer_name, dest_commits[i].author_name
            assert_in_delta c.committer_date, dest_commits[i].author_date, 1

            # The svn-to-git conversion process loses the trailing \n for single-line messages
            assert_equal "#{c.message.strip}\ngit-svn-id: #{c.scm.url}@#{c.token} #{c.scm.uuid}", dest_commits[i].message.strip
          end
        end
      end
    end
  end
end
