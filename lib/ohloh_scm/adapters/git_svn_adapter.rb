module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def english_name
    end
  end
end

require_relative 'git_svn/pull'
require_relative 'git_svn/commits'
require_relative 'git_svn/misc'
require_relative 'git_svn/cat_file'
require_relative 'git_svn/head'
