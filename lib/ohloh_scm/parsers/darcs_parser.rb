module OhlohScm::Parsers
	# This parser can process the default darcs changes output #, with or without the --verbose flag.
	class DarcsParser < Parser
		def self.scm
			'darcs'
		end

		def self.internal_parse(buffer, opts)
			e = nil
			state = :patch
#			email_match = Regexp.new(Regexp.quote('/^(?!(?>(?1)"?(?>\\\[ -~]|[^"])"?(?1)){255,})(?!(?>(?1)"?(?>\\\[ -~]|[^"])"?(?1)){65,}@)((?>(?>(?>((?>(?>(?>\x0D\x0A)?[\x09 ])+|(?>[\x09 ]*\x0D\x0A)?[\x09 ]+)?)(\((?>(?2)(?>[\x01-\x08\x0B\x0C\x0E-\'*-\[\]-\x7F]|\\\[\x00-\x7F]|(?3)))*(?2)\)))+(?2))|(?2))?)([!#-\'*+\/-9=?^-~-]+|"(?>(?2)(?>[\x01-\x08\x0B\x0C\x0E-!#-\[\]-\x7F]|\\\[\x00-\x7F]))*(?2)")(?>(?1)\.(?1)(?4))*(?1)@(?!(?1)[a-z0-9-]{64,})(?1)(?>([a-z0-9](?>[a-z0-9-]*[a-z0-9])?)(?>(?1)\.(?!(?1)[a-z0-9-]{64,})(?1)(?5)){0,126}|\[(?:(?>IPv6:(?>([a-f0-9]{1,4})(?>:(?6)){7}|(?!(?:.*[a-f0-9][:\]]){8,})((?6)(?>:(?6)){0,6})?::(?7)?))|(?>(?>IPv6:(?>(?6)(?>:(?6)){5}:|(?!(?:.*[a-f0-9]:){6,})(?8)?::(?>((?6)(?>:(?6)){0,4}):)?))?(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])(?>\.(?9)){3}))\])(?1)$/isD'))

			buffer.each_line do |l|
				#print "\n#{state}"
				next_state = state
				if state == :patch
					case l
					when /^patch ([0-9a-f]*)/
						yield e if e && block_given?
						e = Scm::Commit.new
						e.diffs = []
						e.token = $1
					when /^Author: (.*)/
						nameemail = $1
						case nameemail
						when /^(\b.*) <([^>]*)>/
							e.author_name = $1
							e.author_email = $2
						when /^([^@]*)$/
							e.author_name = $1
							e.author_email = nil
						else
							e.author_name = nil
							e.author_email = nameemail
						end
					when /^Date:   ([^ ]...........................)/
						e.author_date = Time.parse($1).utc
					when /^  \* (.*)/
						e.message = ($1 || '')
						next_state = :long_comment_or_prims
					end
				elsif state == :long_comment_or_prims
					case l
					when /^    addfile\s+(.+)/
						e.diffs << Scm::Diff.new(:action => 'A', :path => $1)
						next_state = :prims
					when /^    rmfile\s+(.+)/
						e.diffs << Scm::Diff.new(:action => 'D', :path => $1)
						next_state = :prims
					when /^    hunk\s+(.+)\s+([0-9]+)$/
						e.diffs << Scm::Diff.new(:action => 'M', :path => $1)
						# e.sha1, e.parent_sha1 = ...
						next_state = :prims
					when /^$/
						next_state = :patch
					else
						e.message ||= ''
						e.message << l.sub(/^  /,'')
					end

				elsif state == :prims
					case l
					when /^    addfile\s+(.+)/
						e.diffs << Scm::Diff.new(:action => 'A', :path => $1)
					when /^    rmfile\s+(.+)/
						e.diffs << Scm::Diff.new(:action => 'D', :path => $1)
					when /^    hunk\s+(.+)\s+([0-9]+)$/
						e.diffs << Scm::Diff.new(:action => 'M', :path => $1)
						# e.sha1, e.parent_sha1 = ...
					when /^$/
						next_state = :patch
					else
						# ignore hunk details
					end

				end
				state = next_state
			end
			yield e if e && block_given?
		end

	end
end
