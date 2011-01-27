module Scm::Adapters
	class BzrAdapter < AbstractAdapter

		# Return the number of commits in the repository following +after+.
		def commit_count(opts={})
			commit_tokens(opts).size
		end

		# Return the list of commit tokens following +after+.
		def commit_tokens(opts={})
			after = opts[:after]
			tokens = run("#{rev_list_command(opts)} | grep -E -e '^( *)revision-id: ' | cut -f2- -d':' | cut -c 2-").split("\n")

			# Bzr returns everything after *and including* after.
			# We want to exclude it.
			if tokens.any? && tokens.first == after
				tokens[1..-1]
			else
				tokens
			end
		end

		# Returns a list of shallow commits (i.e., the diffs are not populated).
		# Not including the diffs is meant to be a memory savings when
		# we encounter massive repositories.  If you need all commits
		# including diffs, you should use the each_commit() iterator,
		# which only holds one commit in memory at a time.
		def commits(opts={})
			after = opts[:after]
			log = run("#{rev_list_command(opts)} | cat")
			a = Scm::Parsers::BzrParser.parse(log)

			if a.any? && a.first.token == after
				a[1..-1]
			else
				a
			end
		end

		# Returns a single commit, including its diffs
		def verbose_commit(token)
			log = run("cd '#{self.url}' && bzr log --long --show-id -v --limit 1 -c #{to_rev_param(token)}")
			Scm::Parsers::BzrParser.parse(log).first
		end

		# Yields each commit after +after+, including its diffs.
		# The log is stored in a temporary file.
		# This is designed to prevent excessive RAM usage when we
		# encounter a massive repository.  Only a single commit is ever
		# held in memory at once.
		def each_commit(opts={})
			after = opts[:after]
			open_log_file(opts) do |io|
				Scm::Parsers::BzrParser.parse(io) do |commit|
					yield remove_directories(commit) if block_given? && commit.token != after
				end
			end
		end

		# Ohloh tracks only files, not directories. This function removes directories
		# from the commit diffs.
		def remove_directories(commit)
			commit.diffs.delete_if { |d| d.path[-1..-1] == '/' }
			commit
		end


		# Not used by Ohloh proper, but handy for debugging and testing
		def log(opts={})
			run "#{rev_list_command(opts)} -v"
		end

		# Returns a file handle to the log.
		# In our standard, the log should include everything AFTER
		# +after+. However, bzr doesn't work that way; it returns
		# everything after and INCLUDING +after+. Therefore, consumers
		# of this file should check for and reject the duplicate commit.
		def open_log_file(opts={})
			after = opts[:after]
			begin
				if after == head_token # There are no new commits
					# As a time optimization, just create an empty
					# file rather than fetch a log we know will be empty.
					File.open(log_filename, 'w') { }
				else
					run "#{rev_list_command(opts)} -v > #{log_filename}"
				end
				File.open(log_filename, 'r') { |io| yield io }
			ensure
				File.delete(log_filename) if FileTest.exist?(log_filename)
			end
		end

		def log_filename
		  File.join('/tmp', (self.url).gsub(/\W/,'') + '.log')
		end

		def rev_list_command(opts={})
			after = opts[:after]
			"cd '#{self.url}' && bzr log --long --show-id --forward --include-merges -r #{to_rev_param(after)}.."
		end
	end
end
