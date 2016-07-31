module OhlohScm::Adapters
  class DarcsAdapter < AbstractAdapter
    def patch_for_commit(commit)
      run("cd '#{url}' && darcs changes -h'#{commit.token}' -v")
    end
  end
end
