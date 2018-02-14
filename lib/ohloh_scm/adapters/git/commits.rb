module OhlohScm::Adapters
	class GitAdapter < AbstractAdapter

		# Returns the number of commits in the repository following the commit with SHA1 'after'.
		def commit_count(opts={})
			run("#{rev_list_command(opts)} | wc -l").to_i
		end

		# Returns the SHA1 hash for every commit in the repository following the commit with SHA1 'after'.
		def commit_tokens(opts={})
			run(rev_list_command(opts)).split("\n")
		end

		# Yields each commit following the commit with SHA1 'after'.
		# Officially, this method isn't required to provide diffs with these commits,
    # and the Subversion equivalent of this method does not,
		# so if you really require the diffs you should be using each_commit() instead.
		def commits(opts={})
			result = []
			each_commit(opts) { |c| result << c }
			result
		end

		# Yields each commit in the repository following the commit with SHA1 'after'.
		# These commits are populated with diffs.
		def each_commit(opts={})

			# Bug fix (hack) follows.
			#
			# git-whatchanged emits a merge commit multiple times, once for each parent, giving the
			# delta to each parent in turn.
			#
			# This causes us to emit too many commits, with repeated merge commits.
			#
			# To fix this, we track the previous commit, and emit a new commit only if it is distinct
			# from the previous.
			#
			# This means that the diffs for a merge commit yielded by this method will be the diffs
			# vs. the first parent only, and diffs vs. other parents are lost. For Ohloh, this is fine
			# because Ohloh ignores merge diffs anyway.

			previous = nil
      open_log_file(opts) do |io|
			  OhlohScm::Parsers::GitStyledParser.parse(io) do |e|
				  yield fixup_null_merge(e) unless previous && previous.token == e.token
				  previous = e
			  end
      end
		end

		# Returns a single commit, including its diffs
		def verbose_commit(token)
			c = OhlohScm::Parsers::GitStyledParser.parse(run("cd '#{url}' && #{OhlohScm::Parsers::GitStyledParser.whatchanged} #{token} | #{ string_encoder }")).first
      fixup_null_merge(c)
		end

    # For a merge commit, we ask `git whatchanged` to output the changes relative to each parent.
    # It is possible, through developer hackery, to create a merge commit which does not change the tree.
    # When this happens, `git whatchanged` will suppress its output relative to the first parent,
    # and jump immediately to the second (branch) parent. Our code mistakenly interprets this output
    # as the missing changes relative to the first parent.
    #
    # To avoid this calamity, we must compare the tree hash of this commit with its first parent's.
    # If they are the same, then the diff should be empty, regardless of what `git whatchanged` says.
    #
    # Yes, this is a convoluted, time-wasting hack to address a very rare circumstance. Ultimatley
    # we should stop parsing `git whatchanged` to extract commit data.
    def fixup_null_merge(c)
      first_parent_token = parent_tokens(c).first
      if first_parent_token && get_commit_tree(first_parent_token) == get_commit_tree(c.token)
        c.diffs = []
      end
      c
    end

		# Retrieves the git log in the format expected by GitStyledParser.
		# We get the log forward chronological order (oldest first)
		def log(opts={})
			if has_branch?
				if opts[:after] && opts[:after]==self.head_token
					'' # Nothing new.
				else
					run "#{rev_list_command(opts)} | xargs -n 1 #{OhlohScm::Parsers::GitStyledParser.whatchanged} | #{ string_encoder }"
				end
			else
				''
			end
		end


		# Same as log() method above, except that it writes the log to 
    # a file.
		def open_log_file(opts={})
			if has_branch?
				if opts[:after] && opts[:after]==self.head_token
					'' # Nothing new.
				else
          begin
					  run "#{rev_list_command(opts)} | xargs -n 1 #{OhlohScm::Parsers::GitStyledParser.whatchanged} | #{ string_encoder } > #{log_filename}"
            File.open(log_filename, 'r') { |io| yield io } 
          ensure
            File.delete(log_filename) if FileTest.exist?(log_filename)
          end
				end
			else
				''
			end
		end

    def log_filename
      File.join(temp_folder, (self.url).gsub(/\W/,'') + '.log')
    end 

		def rev_list_command(opts={})
      up_to = opts[:up_to] || "heads/#{branch_name}"
			range = opts[:after] ? "#{opts[:after]}..#{up_to}" : up_to

      trunk_only = opts[:trunk_only] ? "--first-parent" : ""
			"cd '#{url}' && git rev-list --topo-order --reverse #{trunk_only} #{range}"
		end
	end
end
