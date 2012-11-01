module Scm::Adapters
  class MtnAdapter < AbstractAdapter
    # Retrieve diff of a specific commit
    def patch_for_commit(commit)
      parent_tokens(commit).map {|token|
        run("cd '#{url}' && mtn diff -r #{token} -r #{commit.token}")
      }.join("\n")
    end
  end
end
