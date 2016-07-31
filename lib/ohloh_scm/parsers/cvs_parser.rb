module OhlohScm::Parsers
	class CvsParser < Parser

		def self.scm
			'cvs'
		end

		# Given an IO to a CVS rlog, returns a list of
		# commits (developer/date/message).
		# If a branch_name is specified, only commits along that branch will be returned,
		# otherwise only commits along the head will be returned.
		def self.internal_parse(io, opts)
			commits = {}
			branch_name = opts[:branch_name]
			branch_name = nil if branch_name == 'HEAD' or branch_name == ''

			read_files(io, branch_name) do |c|
				# As commits are yielded by the parser, we sort them into bins.
				#
				# The 'bins' are arrays of timestamps. We keep a separate array of
				# timestamps for each developer/message combination.
				#
				# If a commit lies near in time to another commit with the same
				# developer/message combination, then we merge them and store only
				# the later of the two timestamps.
				#
				# Typically, we end up with only a single timestamp for each developer/message
				# combination. However, if a developer repeatedly uses the same message
				# a number of separate times, we may end up with several timestamps for
				# that combination.

				key = c.committer_name + ":" + c.message
				if commits.has_key? key
					# We have already seen this developer/message combination
					match = false
					commits[key].each_index do |i|
						# Does the new commit lie near in time to a known one in our list?
						if near?(commits[key][i].committer_date, c.committer_date)
							match = true
							# Yes. Choose the most recent timestamp, and add the new
							# directory name to our list.
							if commits[key][i].committer_date < c.committer_date
								commits[key][i].committer_date = c.committer_date
								commits[key][i].token = c.token
							end
							commits[key][i].directories << c.directories[0] unless commits[key][i].directories.include? c.directories[0]
							break
						end
					end
					# This commit lies a long time away from any one we know.
					# Add it to the list as a new checkin event.
					commits[key] << c unless match
				else
					# We have never seen this developer/message combination. Start a new list.
					commits[key] = [c]
				end
			end
			# Pull all of the commits out of the hash and return them as a single sorted list.
			result = commits.values.flatten.sort! { |a,b| a.committer_date <=> b.committer_date }

			# If we have two commits with identical timestamps, arbitrarily choose the first
			(result.size-1).downto(1) do |i|
				result.delete_at(i) if result[i].committer_date == result[i-1].committer_date
			end

			if block_given?
				result.each { |r| yield r }
			end
		end

		# Accepts two dates and determines wether they are close enough together to consider simultaneous.
		def self.near?(a,b)
			((a-b).abs < 30*60) # Less than 30 minutes counts as 'near'
		end

		def self.read_files(io, branch_name, &block)
			io.each_line do |l|
				if l =~ /^RCS file: (.*),.$/
					filename = $1
					read_file(io, branch_name, filename, &block)
				end
			end
		end

		def self.read_file(io, branch_name, filename, &block)
			branch_number = nil
			io.each_line do |l|
				if l =~ /^head: ([\d\.]+)/
					unless branch_name
						branch_number = BranchNumber.new($1)
					end
				elsif l =~ /^symbolic names:/
					if branch_name
						branch_number = read_symbolic_names(io, branch_name)
					end
				elsif l =~ /^----------------------------/
					read_commits(io, branch_number, filename, &block)
					return
				end
			end
		end

		def self.read_symbolic_names(io, branch_name)
			branch_number = nil
			io.each_line do |l|
				if l =~ /^\s+([^:]+): ([\d\.]+)/
					branch_number = BranchNumber.new($2) if $1 == branch_name
				else
					return branch_number
				end
			end
		end

		def self.read_commits(io, branch_number, filename, &block)
			should_yield = nil
			io.each_line do |l|
				if l =~ /^\s$/
					return
				elsif l =~ /^revision ([\d.]+)/
					commit_number = $1
					if branch_number
						should_yield = branch_number.on_same_line?(BranchNumber.new(commit_number))
					else
						should_yield = false
					end
					read_commit(io, filename, commit_number, should_yield, &block)
				end
			end
		end

		def self.read_commit(io, filename, commit_number, should_yield)
			io.each_line do |l|
				if l =~ /^date: (.*);  author: ([^;]+);  state: (\w+);/
					committer_date = $1
					committer_name = $2
					state = $3
					# CVS creates a "phantom" dead file at 1.1 on the head if a file
					#   is created on a branch. Ignore this file.
					should_yield = false if commit_number == '1.1' and state == 'dead'
					message = read_message(io)
					if should_yield
						commit = OhlohScm::Commit.new
						commit.token = committer_date[0..18]
						commit.committer_date = Time.parse(committer_date[0..18] + ' +0000').utc
						commit.committer_name = committer_name
						commit.message = message
						commit.directories = [File.dirname(filename).intern]
						yield commit
					end
					return
				end
			end
		end

		def self.read_message(io)
			message = ''
			first_line = true
			io.each_line do |l|
				if l =~ /^branches: / and first_line # the first line might be 'branches:', skip it.
					# do nothing
				else
					l.chomp!
					if l == '=============================================================================' or
						l == '----------------------------'
						return message
					end
					message += "\n" if message.length != 0
					message += l
				end
				first_line = false
			end
			message
		end
	end

	if $0 == __FILE__
		require File.dirname(__FILE__) + '/../../config/environment'
		LogParser.parse(STDIN).each do |r|
			r.pretty_print(STDOUT)
		end
	end
end
