module OhlohScm::Parsers
	# This parser can process the default bzr logs, with or without the --verbose flag.
	class BzrParser < Parser
		def self.scm
			'bzr'
		end

		def self.internal_parse(buffer, opts)
			e = nil
			state = :data
			action = ''
			indent = '' # Track the level of indentation as we descend into branches
			show_id = false # true if this log includes revision and file ids

			buffer.each_line do |l|
				next_state = state

				case l
				# A commit message can contain lines of only dashes, which makes parsing difficult.
				#
				# This delimiter detector filters most casual cases of using dash lines in commits.
				# We check that the dashed line is exactly 60 chars long, and is prepended by 4*n spaces.
				#
				# Unless the commit message itself includes leading spaces, the commit message will
				# begin in column 4*n+2, and thus will not match our pattern.
				when /^((    )*)-{60,60}$/
					# a new commit begins
					indent = $1
					if e && block_given?
						e.diffs = remove_dupes(e.diffs)
						yield e
					end
					e = OhlohScm::Commit.new
					e.diffs = []
					next_state = :data
				when /^#{indent}revno:\s+(\d+)$/
					e.token = $1
					next_state = :data
				when /^#{indent}revision-id:\s+(\S+)$/
					e.token = $1
					show_id = true
					next_state = :data
				when /^#{indent}author:\s+(.+?)(\s+<(.+)>)?$/
					e.author_name = $1
					e.author_email = $3
					next_state = :data
				when /^#{indent}committer:\s+(.+?)(\s+<(.+)>)?$/
					e.committer_name = $1
					e.committer_email = $3
					next_state = :data
				when /^#{indent}timestamp:\s+(.+)/
					e.committer_date = Time.parse($1)
					next_state = :data
				when /^#{indent}added:$/
					next_state = :collect_files
					action = 'A'
				when /^#{indent}modified:$/
					next_state = :collect_files
					action = 'M'
				when /^#{indent}removed:$/
					next_state = :collect_files
					action = 'D'
				when /^#{indent}renamed:$/
					next_state = :collect_files
					action = :rename
				when /^#{indent}message:$/
					next_state = :collect_message
					e.message ||= ''
				when /^#{indent}  (.*)$/
					case state
					when :collect_files
						line = $1
						# strip the id from the end of the line if it is present
						line = $1 if show_id && line =~ /^(.+?)\s+(\S+)$/
						parse_diffs(action, line).each { |d| e.diffs << d }
					when :collect_message
						e.message << $1
						e.message << "\n"
					end
				end

				state = next_state
			end
			if e && block_given?
				e.diffs = remove_dupes(e.diffs)
				yield e
			end
		end

		# Given a line from the log represent a file operation,
		# return a collection of diffs for that action
		def self.parse_diffs(action, line)
			case action
			when :rename
				# A rename action requires two diffs: one to remove the old filename,
				# another to add the new filename.
				#
				# Note that is possible to be renamed to the empty string!
				# This happens when a subdirectory is moved to become the root.
				before, after = line.scan(/(.+) => ?(.*)/).first
				[ OhlohScm::Diff.new(:action => 'D', :path => before),
					OhlohScm::Diff.new(:action => 'A', :path => after || '' )]
			else
				[OhlohScm::Diff.new(:action => action, :path => line)]
			end.each do |d|
				d.path = strip_trailing_asterisk(d.path)
			end
		end

		def self.strip_trailing_asterisk(path)
			path[-1..-1] == '*' ? path[0..-2] : path
		end

		def self.remove_dupes(diffs)
			# Bazaar may report that a file was added and modified in a single commit.
			# Reduce these cases to a single 'A' action.
			diffs.delete_if do |d|
				d.action == 'M' && diffs.select { |x| x.path == d.path && x.action == 'A' }.any?
			end

			# Bazaar may report that a file was both deleted and added in a single commit.
			# Reduce these cases to a single 'M' action.
			diffs.each do |d|
				d.action = 'M' if diffs.select { |x| x.path == d.path }.size > 1
			end.uniq
		end
	end
end
