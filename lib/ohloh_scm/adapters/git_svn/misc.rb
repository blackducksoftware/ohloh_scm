module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def exist?
      !!(head_token)
    end

    def export(dest_dir, rev = nil)
      commit_sha1 = rev ? find_git_token(rev) : :HEAD

      run_in_url "git archive #{ commit_sha1 } | tar -C #{ dest_dir } -x"
    end

    private

    def run_in_url(command)
      run "cd #{ url } && #{ command }"
    end

    def find_git_token(svn_token)
      token = run_in_url("git svn find-rev r#{ svn_token }")
      raise 'Unable to find git rev for given svn token' if token.to_s.empty?
      token.chomp
    end
  end
end
