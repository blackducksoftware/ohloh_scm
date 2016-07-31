module OhlohScm::Parsers
	class SvnParser < Parser
		def self.scm
			'svn'
		end

		def self.internal_parse(buffer, opts)
			e = nil
			state = :data

			buffer.each_line do |l|
				l.chomp!
				next_state = state
				if state == :data
					if l =~ /^r(\d+) \| (.*) \| (\d+-\d+-\d+ .*) \(.*\) \| .*/
						e = OhlohScm::Commit.new
						e.token = $1.to_i
						e.committer_name = $2
						e.committer_date = Time.parse($3).utc
					elsif l == "Changed paths:"
						next_state = :diffs
					elsif l.empty?
						next_state = :comment
					end

				elsif state == :diffs
					if l =~ /^   (\w) ([^\(\)]+)( \(from (.+):(\d+)\))?$/
						e.diffs ||= []
						e.diffs << OhlohScm::Diff.new(:action => $1, :path => $2, :from_path => $4, :from_revision => $5.to_i)
					else
						next_state = :comment
					end

				# The :log_embedded_within_comment state is special-case code to fix the Wireshark project, which
				# includes fragments of svn logs within its comment blocks, which really confuses the parser.
				# I am not sure whether only Wireshark does this, but I suspect it happens because there is a tool
				# out there somethere to generate these embedded log comments.
				elsif state == :log_embedded_within_comment
					e.message << "\n"
					e.message << l
					next_state = :comment if l =~ /============================ .* log end =+/

				elsif state == :comment
					if l =~ /------------------------------------------------------------------------/
						yield e if block_given?
						e = nil
						next_state = :data
					elsif l =~ /============================ .* log start =+/
						e.message << "\n"
						e.message << l
						next_state = :log_embedded_within_comment
					else
						if e.message
							e.message << "\n"
							e.message << l
						else
							e.message = l
						end
					end
				end
				state = next_state
			end
			yield e if block_given?
		end
	end
end
