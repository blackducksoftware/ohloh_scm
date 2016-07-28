module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def exist?
      !!(head_token)
    end

    private

    def run_in_url(command)
      run "cd #{ url_without_file_protocol } && #{ command }"
    end

    def url_without_file_protocol
      url.gsub('file://', '')
    end

    def find_git_token(svn_token)
      token = run_in_url("git svn find-rev r#{ svn_token }")
      raise 'Unable to find git rev for given svn token' if token.to_s.empty?
      token.chomp
    end
  end
end
