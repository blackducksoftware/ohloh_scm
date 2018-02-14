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
      branch_name = 'trunk'

      with_svn_repository('svn', branch_name) do |source_scm|
        OhlohScm::ScratchDir.new do |dest_dir|
          OhlohScm::ScratchDir.new do |svn_working_folder|
            git_svn = GitSvnAdapter.new(:url => dest_dir).normalize
            git_svn.pull(source_scm)
            assert_equal 4, git_svn.commit_count

            message = 'new commit'
            source_scm_db_path = source_scm.path.sub('trunk', 'db')
            system "cd #{ svn_working_folder } && svn co #{ source_scm.url } && cd #{ branch_name } &&
                    mkdir -p #{ source_scm_db_path }/transactions &&
                    touch one && svn add one && svn commit -m '#{ message }' && svn update"

            git_svn.pull(source_scm)

            assert_equal 5, git_svn.commit_count
            assert_equal message, git_svn.commits.last.message.chomp
          end
        end
      end
    end
  end
end
