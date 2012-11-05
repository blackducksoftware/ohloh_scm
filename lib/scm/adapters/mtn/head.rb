module Scm::Adapters
  class MtnAdapter < AbstractAdapter
  
    # Retrieve the last SHA1 cert inserted in database
    def head_token
      token = run("cd '#{url}' && mtn automate heads").chomp
    end
    
    # Retrieve the whole last commit
    def head
      verbose_commit(head_token)
    end
    
    # Retrieve the parent tokens from a specific commit
    def parent_tokens(commit)
      run("cd '#{url}' && mtn automate parents  #{commit.token}").chomp
    end
    
    # Retrieve parent commits info as Scm::Commit
    def parents(commit)
      parent_tokens(commit).collect { |token| verbose_commit(token) }
    end
  end
end
