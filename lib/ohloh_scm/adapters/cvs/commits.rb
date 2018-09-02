module OhlohScm::Adapters
	class CvsAdapter
		def commits(opts={})
			after = opts[:after]
			result = []

			open_log_file(opts) do |io|
				result = OhlohScm::Parsers::CvsParser.parse(io, :branch_name => branch_name)
			end

			# Git converter needs a backpointer to the scm for each commit
			result.each { |c| c.scm = self }

			return result if result.size == 0 # Nothing found; we're done here.
			return result if after.to_s == '' # We requested everything, so just return everything.

			# We must now remove any duplicates caused by timestamp fudge factors,
			# and only return commits with timestamp > after.

			# If the first commit is newer than after, then the whole list is new and we can simply return.
			return result if parse_time(result.first.token) > parse_time(after)

			# Walk the list of commits to find the first new one, throwing away all of the old ones.

			# I want to string-compare timestamps without converting to dates objects (I think it's faster).
			# Some CVS servers print dates as 2006/01/02 03:04:05, others as 2006-01-02 03:04:05.
			# To work around this, we'll build a regex that matches either date format.
			re = Regexp.new(after.gsub(/[\/-]/, '.'))

			result.each_index do |i|
				if result[i].token =~ re # We found the match for after
					if i == result.size-1
						return [] # There aren't any new commits.
					else
						return result[i+1..-1]
					end
				end
			end

			# Something bad is going on: 'after' does not match any timestamp in the rlog.
			# This is very rare, but it can happen.
			#
			# Often this means that the *last* time we ran commits(), there was some kind of
			# undetected problem (CVS was in an intermediate state?) so the list of timestamps we
			# calculated last time does not match the list of timestamps we calculated this time.
			#
			# There's no work around for this condition here in the code, but there are some things
			# you can try manually to fix the problem. Typically, you can try throwing way the
			# commit associated with 'after' and fetching it again (git reset --hard HEAD^).
			raise RuntimeError.new("token '#{after}' not found in rlog.")
		end

		# Gets the rlog of the repository and saves it in a temporary file.
		# If you pass a timestamp token, then only commits after the timestamp will be returned.
		#
		# Warning!
		#
		# CVS servers are apparently unreliable when you truncate the log by timestamp -- perhaps round-off error?
		# In any case, to be sure not to miss any commits, this method subtracts 10 seconds from the provided timestamp.
		# This means that the returned log might actually contain a few revisions that predate the requested time.
		# That's better than missing revisions completely! Just be sure to check for duplicates.
		def open_log_file(opts={})
			after = opts[:after]
			begin
        ensure_host_key
        return if has_lock?
				run "cvsnt -d #{self.url} rlog #{opt_branch} #{opt_time(after)} '#{self.module_name}' > #{rlog_filename}"
				File.open(rlog_filename, 'r') do |file|
					yield file
				end
			ensure
				File.delete rlog_filename if FileTest.exists?(rlog_filename)
			end
		end

		def opt_time(after=nil)
			if after
				most_recent_time = parse_time(after) - 10
				" -d '#{most_recent_time.strftime('%Y-%m-%d %H:%M:%S')}Z<#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}Z' "
			else
				""
			end
		end

		def rlog_filename
		  File.join(temp_folder, (self.url + self.module_name.to_s + self.branch_name.to_s).gsub(/\W/,'') + '.rlog')
		end

		# Converts a CVS time string to a Ruby Time object
		def parse_time(token)
			case token
			when /(\d\d\d\d).(\d\d).(\d\d) (\d\d):(\d\d):(\d\d)/
				Time.gm( $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i )
			end
		end
	end
end
