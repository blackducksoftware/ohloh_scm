module Scm::Parsers
	# This parser can process the default darcs changes output #, with or without the --verbose flag.
	class DarcsParser < Parser
		def self.scm
			'darcs'
		end

		def self.internal_parse(buffer, opts)
			e = nil
			state = :patch

			buffer.each_line do |l|
				#print "\n#{state}"
				next_state = state
				if state == :patch
					case l
					when /^([^ ]...........................)  (.*)$/
						yield e if e && block_given?
						e = Scm::Commit.new
						e.author_date = Time.parse($1).utc
						nameemail = $2
						case nameemail
						when /^([^<]*) <(.*)>$/
						  e.author_name = $1
						  e.author_email = $2
						when /^([^@]*)$/
						  e.author_name = $1
						  e.author_email = nil
						else
						  e.author_name = nil
						  e.author_email = nameemail
						end
						e.diffs = []
					when /^  \* (.*)/
						e.token = ($1 || '')
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
