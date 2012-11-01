module Scm::Adapters
  class MtnAdapter < AbstractAdapter
    # Return the content of a file that was subject to a diff
    def cat_file(commit, diff)
      cat(commit.token, diff.path)
    end
    
    # Same as above but for the parent (for displaying diff)
    def cat_file_parent(commit, diff)
      p = parent_tokens(commit)
      cat(p.first, diff.path) if p.first
    end
    
    # Retrieve content of a specific file in a specific revision
    def cat(revision, path)
      out, err = run_with_err("cd '#{url}' && mtn cat -r #{revision} #{escape(path)}")
      return nil if err =~ /No such file in rev/i
      raise RuntimeError.new(err) unless err.to_s == ''
      out
    end
    
    # Escape bash-significant characters in the filename
    # Example:
    #     "Foo Bar & Baz" => "Foo\ Bar\ \&\ Baz"
    def escape(path)
      path.gsub(/[ `'"&()<>|#\$]/) { |c| '\\' + c }
    end
  end
end
