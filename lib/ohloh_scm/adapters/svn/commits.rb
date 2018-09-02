require 'rexml/document'

module OhlohScm::Adapters
	class SvnAdapter < AbstractAdapter

		# In all commit- and log-related methods, 'after' refers to the revision
		# number of the last known commit, and the methods return the commits
		# *following* this commit.
		#
		# Examples:
		#    commits(1) => [rev 2, rev 3, ..., HEAD]
		#    commits(3) => [rev 4, rev 5, ..., HEAD]
		#
		# This is convenient for Ohloh -- Ohloh passes the last commit it is aware
		# of, and these methods return any new commits.

		# The last revision to be analyzed in this repository. Everything after this revision is ignored.
		# The repository is considered to be retired after this point, and under no circumstances should
		# this adapter ever return information regarding commits after this point.
		attr_accessor :final_token

		# Returns the count of commits following revision number 'after'.
		def commit_count(opts={})
			after = (opts[:after] || 0).to_i
			return 0 if final_token && after >= final_token
			run("svn log --trust-server-cert --non-interactive -q -r #{after.to_i + 1}:#{final_token || 'HEAD'} --stop-on-copy '#{SvnAdapter.uri_encode(File.join(root, branch_name.to_s))}@#{final_token || 'HEAD'}' | grep -E -e '^r[0-9]+ ' | wc -l").strip.to_i
		end

		# Returns an array of revision numbers for all commits following revision number 'after'.
		def commit_tokens(opts={})
			after = (opts[:after] || 0).to_i
			return [] if final_token && after >= final_token
			cmd = "svn log --trust-server-cert --non-interactive -q -r #{after + 1}:#{final_token || 'HEAD'} --stop-on-copy '#{SvnAdapter.uri_encode(File.join(root, branch_name.to_s))}@#{final_token || 'HEAD'}' | grep -E -e '^r[0-9]+ ' | cut -f 1 -d '|' | cut -c 2-"
			run(cmd).split.collect { |r| r.to_i }
		end

		# Returns an array of commits following revision number 'after'.
		# These commit objects do not include diffs.
		def commits(opts={})
			list = []
			open_log_file(opts) do |io|
				list = OhlohScm::Parsers::SvnXmlParser.parse(io)
			end
			list.each { |c| c.scm = self }
		end

		# Yields each commit following revision number 'after'. These commit object are populated with diffs.
		#
		# With Subversion, populating the diffs can be tricky because when an entire directory is affected,
		# Subversion abbreviates the log by simply listing the directory name, rather than all of the directory
		# contents. Since Ohloh requires the list of every individual file affected, and doesn't care about
		# directories, the complexity (and time) of this method comes in expanding directories with a recursion
		# through every file in the directory.
		#
		def each_commit(opts={})
			commit_tokens(opts).each do |rev|
				yield verbose_commit(rev)
			end
		end

		# For a given commit, replace any diffs that point to directories with diffs for each file that
		# the directory contains.
		def deepen_commit(commit)
			deep_commit = commit.clone
			if commit.diffs
				deep_commit.diffs = commit.diffs.collect do |diff|
					deepen_diff(diff, commit.token)
				end.compact.flatten.uniq.sort { |a,b| a.action <=> b.action }.sort { |a,b| a.path <=> b.path }
			end

			remove_dupes(deep_commit)
		end

		def remove_dupes(commit)
			# Strange case correction.
			#
			# Subversion may report that a directory is added, and then also that a file within that directory is modified.
			# Because we expand directories, the result is that the file may be listed twice -- once as part of our expansion,
			# and once from the regular log entry.
			#
			# So look for diffs of the form ["M", "path"] which are matched by ["A", "path"], and keep only the "A" diff.
			if commit.diffs
				commit.diffs.delete_if do |d|
					d && d.action =~ /[MR]/ && commit.diffs.select { |x| x.action == 'A' and x.path == d.path }.any?
				end
			end
			commit
		end

		# If the diff points to a file, simply returns the diff.
		# If the diff points to a directory, returns an array of diffs for every file in the directory.
		def deepen_diff(diff, rev)
			# Note that if the directory was deleted, we have to look at the previous revision to see what it held.
			recurse_rev = (diff.action == 'D') ? rev-1 : rev

			if (diff.action == 'D' or diff.action == 'A') && is_directory?(diff.path, recurse_rev)
				# Deleting or adding a directory. Expand it out to show every file.
				recurse_files(diff.path, recurse_rev).collect do |f|
					OhlohScm::Diff.new(:action => diff.action, :path => File.join(diff.path, f))
				end
			else
				# An ordinary file action. Just return the diff.
				diff
			end
		end

		# Strip all paths in this commit to remove the leading branch_name.
		# Throw away any diffs in the commit that don't lie in the branch_name we care about.
		def strip_commit_branch(commit)
			stripped_commit = commit.clone
			if commit.diffs
				stripped_commit.diffs = commit.diffs.collect { |d| strip_diff_branch(d) }.compact
			end
			stripped_commit
		end

		# Return a new diff whose path excludes the leading branch_name.
		# If the diff is not in the branch, return nil.
		def strip_diff_branch(diff)
			stripped_diff = diff.clone
			stripped_diff.path = strip_path_branch(diff.path)
			stripped_diff.path && stripped_diff
		end

		# Returns only the portion of the path following branch_name.
		# Returns nil if the path is not within the branch.
		def strip_path_branch(path)
			if path == self.branch_name.to_s
				''
			else
				$1 if path =~ /^#{Regexp.escape(self.branch_name.to_s)}(\/.*)$/
			end
		end

		def verbose_commit(rev)
			c = OhlohScm::Parsers::SvnXmlParser.parse(single_revision_xml(rev)).first
			c.scm = self
			deepen_commit(strip_commit_branch(c))
		end

		#---------------------------------------------------------------------
		# Log-related code ; get log for entire file or single revision
		#---------------------------------------------------------------------

		def log(opts={})
			after = (opts[:after] || 0).to_i
			run "svn log --trust-server-cert --non-interactive --xml --stop-on-copy -r #{after.to_i + 1}:#{final_token || 'HEAD'} '#{SvnAdapter.uri_encode(File.join(self.root, self.branch_name.to_s))}@#{final_token || 'HEAD'}' #{opt_auth}"
		end

		def open_log_file(opts={})
			after = (opts[:after] || 0).to_i
			begin
				if (final_token && after >= final_token) || after >= head_token
					# As a time optimization, just create an empty file rather than fetch a log we know will be empty.
					File.open(log_filename, 'w') { |f| f.puts '<?xml version="1.0"?>' }
				else
					run "svn log --trust-server-cert --non-interactive --xml --stop-on-copy -r #{after + 1}:#{final_token || 'HEAD'} '#{SvnAdapter.uri_encode(File.join(self.root, self.branch_name))}@#{final_token || 'HEAD'}' #{opt_auth} > #{log_filename}"
				end
				File.open(log_filename, 'r') { |io| yield io }
			ensure
				File.delete(log_filename) if FileTest.exist?(log_filename)
			end
		end

		def log_filename
		  File.join(temp_folder, (self.url).gsub(/\W/,'') + '.log')
		end

		# Returns one commit with the exact revision number provided
		def single_revision_xml(revision)
			run "svn log --trust-server-cert --non-interactive --verbose --xml --stop-on-copy -r #{revision} --limit 1 #{opt_auth} '#{SvnAdapter.uri_encode(File.join(self.root, self.branch_name))}@#{revision}'"
		end

		# Recurses the entire repository and returns an array of file names.
		# Directories are not returned.
		# Directories named 'CVSROOT' are always ignored and the files they contain are never returned.
		# An empty array means that the call succeeded, but the remote directory is empty.
		# A nil result means that the call failed and the remote server could not be queried.
		def recurse_files(path=nil, revision=final_token || 'HEAD')
			begin
				stdout = run "svn ls --trust-server-cert --non-interactive -r #{revision} --recursive #{opt_auth} '#{SvnAdapter.uri_encode(File.join(root, branch_name.to_s, path.to_s))}@#{revision}'"
			rescue
				puts $!.inspect
				return nil
			end

			files = []
			stdout.each_line do |s|
				s.chomp!.force_encoding('UTF-8')
				files << s if s.length > 0 and s !~ /CVSROOT\// and s[-1..-1] != '/'
			end
			files.sort
		end
	end
end
