module Scm::Adapters
	class DarcsAdapter < AbstractAdapter

		# Return the number of commits in the repository following +since+.
		def commit_count(since=0)
			commit_tokens(since || 0).size
		end

		# Return the list of commit tokens following +since+.
		def commit_tokens(since=0, up_to='tip')
			# We reverse the final result in Ruby, rather than passing the --reverse flag to darcs.
			# That's because the -f (follow) flag doesn't behave the same in both directions.
			# Basically, we're trying very hard to make this act just like Git. The darcs_rev_list_test checks this.
			tokens = run("cd '#{self.url}' && darcs log -f -r #{up_to || 'tip'}:#{since || 0} --template='{node}\\n'").split("\n").reverse

			# Darcs returns everything after *and including* since.
			# We want to exclude it.
			if tokens.any? && tokens.first == since
				tokens[1..-1]
			else
				tokens
			end
		end

		# Returns a list of shallow commits (i.e., the diffs are not populated).
		# Not including the diffs is meant to be a memory savings when we encounter massive repositories.
		# If you need all commits including diffs, you should use the each_commit() iterator, which only holds one commit
		# in memory at a time.
		def commits(since=0)
			log = run("cd '#{self.url}' && darcs log -f -v -r tip:#{since || 0} --style #{Scm::Parsers::DarcsStyledParser.style_path}")
			a = Scm::Parsers::DarcsStyledParser.parse(log).reverse

			if a.any? && a.first.token == since
				a[1..-1]
			else
				a
			end
		end

		# Returns a single commit, including its diffs
		def verbose_commit(token)
			log = run("cd '#{self.url}' && darcs log -v -r #{token} --style #{Scm::Parsers::DarcsStyledParser.verbose_style_path}")
			Scm::Parsers::DarcsStyledParser.parse(log).first
		end

		# Yields each commit after +since+, including its diffs.
		# The log is stored in a temporary file.
		# This is designed to prevent excessive RAM usage when we encounter a massive repository.
		# Only a single commit is ever held in memory at once.
		def each_commit(since=0)
			open_log_file(since) do |io|
				Scm::Parsers::DarcsStyledParser.parse(io) do |commit|
					yield commit if block_given? && commit.token != since
				end
			end
		end

		# Not used by Ohloh proper, but handy for debugging and testing
		def log(since=0)
			run "cd '#{url}' && darcs log -f -v -r tip:#{since}"
		end

		# Returns a file handle to the log.
		# In our standard, the log should include everything AFTER +since+. However, darcs doesn't work that way;
		# it returns everything after and INCLUDING +since+. Therefore, consumers of this file should check for
		# and reject the duplicate commit.
		def open_log_file(since=0)
			begin
				if since == head_token # There are no new commits
					# As a time optimization, just create an empty file rather than fetch a log we know will be empty.
					File.open(log_filename, 'w') { }
				else
					run "cd '#{url}' && darcs log --verbose -r #{since || 0}:tip --style #{Scm::Parsers::DarcsStyledParser.verbose_style_path} > #{log_filename}"
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
