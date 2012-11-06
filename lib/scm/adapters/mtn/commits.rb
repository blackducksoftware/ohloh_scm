module Scm::Adapters
  class MtnAdapter < AbstractAdapter
    
    # Return the number of commits in the repository following +after+.
    def commit_count(opts={})
      commit_tokens(opts).size
    end
    
    # Return the list of commit tokens following +after+.
    def commit_tokens(opts={})
      # There is no selector for first revision, so we use 0 as marker
      after = opts[:after] || 0
      # We use the h: selector
      up_to = opts[:up_to] || 'h:'

      command = "cd '#{self.url}' && mtn automate log --from #{up_to} "

      # We only put an "after" revision if :after was set
      if after != 0 then
        command = command + "--to #{after} "
        
        # deals with the case where :after is the same as head
        if after == head_token then
          return [];
        end
      end
      
      # run the command to retrieve tokens and split by newline character
      tokens = run(command).split("\n")

      return tokens
    end

    # Returns a list of shallow commits (i.e., the diffs are not populated).
    # Not including the diffs is meant to be a memory savings when we encounter massive repositories.
    # If you need all commits including diffs, you should use the each_commit() iterator, which only holds one commit
    # in memory at a time.
    def commits(opts={})
      after = opts[:after] || 0
      
      # Array of ScmCommit to be returned
      commits_info = Array.new

      #First of all we retrieve the commit tokens
      tokens = commit_tokens(:after => after)
      tokens.each { |token|
        # for each token, we get the commit info from simple_commit
        # and add it to the array
        commits_info << simple_commit(token)
      }
      
      # We return it depending on the number of commits
      if commits_info.any? && commits_info.first.token == after
        commits_info[1..-1]
      else
        commits_info
      end
    end

    #This method only return the content of a single commit as a ScmCommit without diff
    def simple_commit(token)
      log = run("cd '#{self.url}' && mtn automate --date-format '%Y%M%dT%H%m%S%z' certs #{token}")
      # Send the output to the parser
      commit = Scm::Parsers::MtnCertsParser.parse(log).first
      # Init the diffs array
      commit.diffs = []

      #Fix the token returned as only the cert of the manifest is returned
      commit.token=token

      return commit
    end

    # Returns a single commit, including its diffs
    def verbose_commit(token)
      # First we get the normal fields for commit
      commit = simple_commit(token)

      # Then we get the diffs
      log = run("cd '#{self.url}' && mtn automate --date-format '%Y%M%dT%H%m%S%z' get_revision #{token}")
      commit.diffs = Scm::Parsers::MtnRevisionParser.parse(log)
      
      return commit
    end

    # Yields each commit following revision number 'after'. These commit object are populated with diffs.
    def each_commit(opts={})
      after = opts[:after] || 0
      open_log_file(opts) do |io|
        while io.eof == false
          # we load objects and yield for each
          commit = Marshal.load(io) 
          yield commit if block_given? && commit.token != after
        end
      end
    end

    # Not used by Ohloh proper, but handy for debugging and testing
    def log(opts={})
      after = opts[:after] || 0

      command = "cd '#{url}' && mtn log --from h:"
      # We only put an "after" revision if :after was set
      if after != 0 then
        command = command + " --to #{after} "
      end

      run command
    end

    # Returns a file handle to the log.
    # In our standard, the log should include everything AFTER +after+. However, hg doesn't work that way;
    # it returns everything after and INCLUDING +after+. Therefore, consumers of this file should check for
    # and reject the duplicate commit.
    def open_log_file(opts={})
      after = opts[:after] || 0
      begin
        if after == head_token # There are no new commits
          # As a time optimization, just create an empty file rather than fetch a log we know will be empty.
          File.open(log_filename, 'w') { }
        else
          # Create a serialization file
          file = File.new(log_filename,'w')

          # Just run the commit_tokens
          tokens = commit_tokens(opts)
          # For each token, we get the verbose commit and marshall it into our "log"
          tokens.each { |token|
            commit = verbose_commit(token)
            file.write(Marshal.dump(commit))
          }
          
          # Then we close the file
          file.close
        end
        File.open(log_filename, 'r') { |io| yield io }
      ensure
        File.delete(log_filename) if FileTest.exist?(log_filename)
      end
    end

    def log_filename
      File.join('/tmp', (self.url).gsub(/\W/,'') + '.log')
    end

  end
end
