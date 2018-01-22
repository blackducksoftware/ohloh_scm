module OhlohScm::Adapters
  class SvnToGitAdapter < GitAdapter
    def english_name
    end
  end
end

require_relative 'svn_to_git/pull'
