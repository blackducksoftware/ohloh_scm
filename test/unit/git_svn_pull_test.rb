require_relative '../test_helper'

module OhlohScm::Adapters
  class GitSvnPullTest < OhlohScm::Test
    def test_svn_conversion_on_pull
			with_svn_repository('svn', 'trunk') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|
					dest = GitSvnAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					dest_commits = dest.commits
          assert_equal dest_commits.map(&:diffs).flatten.map(&:path),
                       ["helloworld.c", "makefile", "README", "helloworld.c", "COPYING"]
          assert_equal dest_commits.map(&:committer_date).map(&:to_s),
            ['2006-06-11 18:28:00 UTC', '2006-06-11 18:32:13 UTC', '2006-06-11 18:34:17 UTC', '2006-07-14 23:07:15 UTC']

					src.commits.each_with_index do |c, i|
						assert_equal c.committer_name, dest_commits[i].committer_name
						assert_equal c.message.strip, dest_commits[i].message.strip
					end
				end
			end
    end

    def test_updated_branch_on_fetch
      with_svn_repository('svn-updated') do |source_scm|
        with_git_svn_repository('git_svn') do |git_svn|
          refute_includes `cd #{ git_svn.url } && git branch -a`, 'remotes/develop'

          `echo "url = #{ source_scm.root }" >> #{ git_svn.url }/.git/config`
          def git_svn.exist?; true end

          git_svn.pull(nil)
          assert_includes `cd #{ git_svn.url } && git branch -a`, 'remotes/develop'
        end
      end
    end
  end
end
