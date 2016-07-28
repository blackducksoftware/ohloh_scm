require_relative '../test_helper'

module OhlohScm::Adapters
  class GitSvnCommitsTest < OhlohScm::Test
    def test_exist
      with_git_svn_repository('git_svn') do |svn|
        assert svn.exist?
      end
    end
  end
end
