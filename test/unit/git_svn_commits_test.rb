require_relative '../test_helper'

module OhlohScm::Adapters
  class GitSvnCommitsTest < OhlohScm::Test
    def test_commit_tokens
      with_git_svn_repository('git_svn') do |git_svn|
        assert_equal [1,2,3,5], git_svn.commit_tokens
        assert_equal [3,5], git_svn.commit_tokens(after: 2)
      end
    end

    def test_commits
      with_git_svn_repository('git_svn') do |git_svn|
        assert_equal [1,2,3,5], git_svn.commits.map(&:token)
        assert_equal [3,5], git_svn.commits(after: 2).map(&:token)
        assert_equal [], git_svn.commits(after: 7)
      end
    end

    def test_each_commit
      with_git_svn_repository('git_svn') do |git_svn|
        commits = []
        git_svn.each_commit { |c| commits << c }
        assert_equal [1,2,3,5], git_svn.commits.map(&:token)
      end
    end
  end
end
