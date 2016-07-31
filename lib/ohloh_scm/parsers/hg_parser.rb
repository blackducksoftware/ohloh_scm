module OhlohScm::Parsers
	# This parser can process the default hg logs, with or without the --verbose flag.
	# It is handy for debugging but is not detailed enough for Ohloh analysis.
	# See the HgStyledParser.
	class HgParser < Parser
		def self.scm
			'hg'
		end

		def self.internal_parse(buffer, opts)
			e = nil
			state = :data

			buffer.each_line do |l|
				next_state = state
				if state == :data
					case l
					when /^changeset:\s+\d+:([0-9a-f]+)/
						yield e if e && block_given?
						e = OhlohScm::Commit.new
						e.diffs = []
						e.token = $1
					when /^user:\s+(.+?)(\s+<(.+)>)?$/
						e.committer_name = $1
						e.committer_email = $3
					when /^date:\s+(.+)/
						e.committer_date = Time.parse($1).utc
					when /^files:\s+(.+)/
						($1 || '').split(' ').each do |file|
							e.diffs << OhlohScm::Diff.new(:action => '?', :path => file)
						end
					when /^summary:\s+(.+)/
						e.message = $1
					when /^description:/
						next_state = :long_comment
					end

				elsif state == :long_comment
					if l == "\n"
						next_state = :long_comment_following_blank
					else
						e.message ||= ''
						e.message << l
					end

				elsif state == :long_comment_following_blank
					if l == "\n" # A second blank line in a row terminates the comment.
						yield e if block_given?
						e = nil
						next_state = :data
					else # Otherwise resume parsing comments.
						e.message << "\n"
						e.message << l
						next_state = :long_comment
					end
				end
				state = next_state
			end
			yield e if e && block_given?
		end

	end
end
