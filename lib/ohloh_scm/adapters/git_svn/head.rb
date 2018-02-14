module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def head_token
      cmd = "--limit=1 | #{extract_revision_number}"
      git_svn_log(cmd: cmd, oneline: false)
    end
  end
end

