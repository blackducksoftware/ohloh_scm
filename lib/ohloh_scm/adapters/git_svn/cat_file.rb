module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def cat_file(commit, diff)
      cat(git_commit(commit), diff.path)
    end

    def cat_file_parent(commit, diff)
      cat("#{ git_commit(commit) }^", diff.path)
    end

    private

    def cat(revision, file_path)
      run("cd #{self.url} && git show #{ revision }:'#{ escape_single_quote(file_path) }'").strip
    end

    def git_commit(commit)
      run("cd #{self.url} && git svn find-rev r#{commit.token}").strip
    end
  end
end
