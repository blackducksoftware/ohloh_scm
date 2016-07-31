module OhlohScm::Parsers
	# This parser processes Git whatchanged generated using a custom style.
	# This custom style provides additional information required by Ohloh.
	class GitStyledParser < Parser
		def self.scm
			'git'
		end

		def self.whatchanged
			"git whatchanged --root -m --abbrev=40 --max-count=1 --always --pretty=#{format}"
		end

		def self.format
		  "format:'__BEGIN_COMMIT__%nCommit: %H%nAuthor: %an%nAuthorEmail: %ae%nDate: %aD%n__BEGIN_COMMENT__%n%s%n%b%n__END_COMMENT__%n'"
		end

		ANONYMOUS = "(no author)" unless defined?(ANONYMOUS)

		def self.internal_parse(io, opts)
			e = nil
			state = :key_values

			io.each do |line|
				line.chomp!

				# Kind of a hack: the diffs section is not always present.
				# If we are expecting a line of diffs, but instead find a line
				# starting with "Commit: ", that means the diffs section
				# is missing for this commit,  and we need to fix up our state.
				if state == :diffs and line =~ /^Commit: ([a-z0-9]+)$/
					state = :key_values
				end

				if state == :key_values
					if line =~ /^Commit: ([a-z0-9]+)$/
						sha1 = $1
						yield e if e
						e = OhlohScm::Commit.new
						e.diffs = []
						e.token = sha1
						e.author_name = ANONYMOUS
					elsif line =~ /^Author: (.+)$/
						e.author_name = $1
					elsif line =~ /^Date: (.*)$/
            # MUST be RFC2822 format to parse properly, else defaults to epoch time
            e.author_date = parse_date($1)
					elsif line == "__BEGIN_COMMENT__"
						state = :message
					elsif line =~ /^AuthorEmail: (.+)$/
						e.author_email = $1
						# In the rare case that the Git repository does not contain any names (see OpenEmbedded for example)
						# we use the email instead.
						e.author_name = $1 if e.author_name.to_s.empty? || e.author_name == ANONYMOUS
					end

				elsif state == :message
					if line == "__END_COMMENT__"
						state = :diffs
					elsif line != "<unknown>"
						if e.message
							e.message << "\n" << line
						else
							e.message = line
						end
					end

				elsif state == :diffs
					if line == "__BEGIN_COMMIT__"
						state = :key_values
					elsif line =~ /:([0-9]+) ([0-9]+) ([a-z0-9]+) ([a-z0-9]+) ([A-Z])\t"?(.+[^"])"?$/
						# Submodules have a file mode of '160000', which indicates a "gitlink"
						# We ignore submodules completely.
						e.diffs << OhlohScm::Diff.new( :action => $5, :path => $6, :sha1 => $4, :parent_sha1 => $3 ) unless $1=='160000' || $2=='160000'
					end

				else
					raise RuntimeError("Unknown parser state #{state.to_s}")
				end
			end

			yield e if e
		end

    def self.parse_date(date)
      t = Time.rfc2822(date) rescue Time.at(0)
      t.utc
    end
	end
end
