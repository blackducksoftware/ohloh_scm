module OhlohScm::Adapters
	class DarcsAdapter < AbstractAdapter

		# Return the number of commits in the repository following +since+.
		def commit_count(opts={})
			commit_tokens(opts).size
		end

		# Return the list of commit tokens following +since+.
		def commit_tokens(opts={})
			after = opts[:after] ? " --from-match 'hash #{opts[:after]}'" : ""
			up_to = opts[:up_to] ? " --to-match 'hash #{opts[:up_to]}'" : ""
			tokens = string_to_patch_tokens(run("cd '#{self.url}' && darcs changes#{after}#{up_to}")).reverse

			# Darcs returns everything after *and including* since.
			# We want to exclude it.
			if tokens.any? && tokens.first == opts[:after]
				tokens[1..-1]
			else
				tokens
			end
		end

		# Returns a list of shallow commits (i.e., the diffs are not populated).
		# Not including the diffs is meant to be a memory savings when we encounter massive repositories.
		# If you need all commits including diffs, you should use the each_commit() iterator, which only holds one commit
		# in memory at a time.
		def commits(opts={})
			after = opts[:after] ? " --from-match 'hash #{opts[:after]}'" : ""
			log = run("cd '#{self.url}' && darcs changes#{after} --reverse")
			a = OhlohScm::Parsers::DarcsParser.parse(log)
			if a.any? && a.first.token == opts[:after]
				a[1..-1]
			else
				a
			end
		end

		# Returns a single commit, including its diffs
		def verbose_commit(token)
			log = run("cd '#{self.url}' && darcs changes -v -h '#{token}'")
			OhlohScm::Parsers::DarcsParser.parse(log).first
		end

		# Yields each commit after +since+, including its diffs.
		# The log is stored in a temporary file.
		# This is designed to prevent excessive RAM usage when we encounter a massive repository.
		# Only a single commit is ever held in memory at once.
		def each_commit(opts={})
			open_log_file(opts) do |io|
				OhlohScm::Parsers::DarcsParser.parse(io) do |commit|
					yield commit if block_given? && commit.token != opts[:after]
				end
			end
		end

		# Not used by Ohloh proper, but handy for debugging and testing
		def log(opts={})
      after = opts[:after] ? " --from-match 'hash #{opts[:after]}'" : ""
			run "cd '#{url}' && darcs changes -s#{after}"
		end

		# Returns a file handle to the log.
		# In our standard, the log should include everything AFTER +since+. However, darcs doesn't work that way;
		# it returns everything after and INCLUDING +since+. Therefore, consumers of this file should check for
		# and reject the duplicate commit.
		def open_log_file(opts={})
			after = opts[:after] ? " --from-match 'hash #{opts[:after]}'" : ''
			begin
				if opts[:after] == head_token # There are no new commits
					# As a time optimization, just create an empty file rather than fetch a log we know will be empty.
					File.open(log_filename, 'w') { }
				else
					after = opts[:after] ? " --from-match 'hash #{opts[:after]}'" : ""
					run "cd '#{url}' && darcs changes --reverse -v#{after} > #{log_filename}"
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
