module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def git_svn_log(cmd:, oneline:)
      oneline_flag = '--oneline' if oneline
      run("#{git_svn_log_cmd} #{oneline_flag} #{cmd}").strip
    end

    private

    def git_svn_log_cmd
      "cd #{self.url} && git svn log"
    end
  end
end
