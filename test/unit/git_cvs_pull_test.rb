require_relative '../test_helper'

module OhlohScm::Adapters
  class GitCvsPullTest < OhlohScm::Test
    def test_cvs_conversion_on_pull
      with_cvs_repository('cvs', 'simple') do |src|
        OhlohScm::ScratchDir.new do |dest_dir|
          dest = GitCvsAdapter.new(:url => dest_dir).normalize
          assert !dest.exist?

          dest.pull(src)
          assert dest.exist?

          dest_commits = dest.commits
          assert_equal dest_commits.map(&:diffs).flatten.map(&:path),
            ['foo.rb', 'new_file.rb', 'another_file.rb', 'late_addition.rb', 'late_addition.rb']
          assert_equal dest_commits.map(&:author_date).map(&:to_s),
            ['2006-06-29 16:21:07 UTC', '2006-06-29 18:14:47 UTC', '2006-06-29 18:45:29 UTC', '2006-06-29 18:48:54 UTC', '2006-06-29 18:52:23 UTC']

          src.commits.each_with_index do |c, i|
            assert_equal c.committer_name, dest_commits[i].author_name
            assert_equal c.message.strip, dest_commits[i].message.strip
          end
        end
      end
    end

    def test_updated_branch_on_fetch
      module_name = 'simple'

      with_cvs_repository('cvs', module_name) do |src|
        OhlohScm::ScratchDir.new do |dest_dir|
          OhlohScm::ScratchDir.new do |cvs_working_folder|
            dest = GitCvsAdapter.new(:url => dest_dir).normalize
            dest.pull(src)
            assert_equal dest.commit_count, 5

            system "cd #{ cvs_working_folder } && cvs -d #{ src.url } co #{ module_name }"
            cvs_working_path = cvs_working_folder + '/' + module_name
            system "cd #{ cvs_working_path } && touch one && cvs add one && cvs commit -m 'added file one'"

            dest.pull(src)
            assert_equal dest.commit_count, 6
          end
        end
      end
    end
  end
end
