module Scm::Adapters
  class DarcsAdapter < AbstractAdapter
    def patch_for_commit(commit)
      parent_tokens(commit).map {|token|
        run("darcs -R '#{url}' diff --git -r#{token} -r#{commit.token}")
      }.join("\n")
    end
  end
end
