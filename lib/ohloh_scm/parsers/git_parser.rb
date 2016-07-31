module OhlohScm::Parsers
	class GitParser < Parser
		def self.scm
			'git'
		end

		ANONYMOUS = "(no author)" unless defined?(ANONYMOUS)

		def self.internal_parse(io, opts)
			e = nil
			state = :key_values

			io.each do |line|
				line.chomp!

				# Kind of a hack: the diffs section is not always present.
				# Also, we don't know when the next commit is going to begin,
				# so we may need to make an unexpected state change.
				if line =~ /^commit ([a-z0-9]{40,40})$/
					state = :key_values
				elsif state == :message and line =~ /^[ADM]\s+(.+)$/
					state = :diffs
				end

				if state == :key_values
					case line
					when /^commit ([a-z0-9]{40,40})$/
						sha1 = $1
						yield e if e
						e = OhlohScm::Commit.new
						e.diffs = []
						e.token = sha1
						e.author_name = ANONYMOUS
					when /^Author: (.+) <(.*)>$/
						# In the rare case that the Git repository does not contain any names (see OpenEmbedded for example)
						# we use the email instead.
						e.author_name = $1 || $2
						e.author_email = $2
					when /^Date: (.*)$/
						e.author_date = Time.parse($1).utc # Note strongly: MUST be RFC2822 format to parse properly
						state = :message
					end

				elsif state == :message
					case line
					when /    (.*)/
						if e.message
							e.message << "\n" << $1
						else
							e.message = $1
						end
					end

				elsif state == :diffs
					if line =~ /^([ADM])\t(.+)$/
						e.diffs << OhlohScm::Diff.new( :action => $1, :path => $2)
					end

				else
					raise RuntimeError("Unknown parser state #{state.to_s}")
				end
			end

			yield e if e
		end
	end
end
