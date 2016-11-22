module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def cat_file(commit, diff)
      cat(git_token(commit), diff.path)
    end

    def cat_file_parent(commit, diff)
      cat("#{ git_token(commit) }^", diff.path)
    end

    private

    def cat(rev, filepath)
      run_in_url "git show #{ rev }:#{ filepath }"
    rescue
      raise unless $!.message =~ /(Path '.+' does not exist in|Invalid object name)/
    end

    def git_token(commit)
      find_git_token(commit.token)
    end
  end
end
