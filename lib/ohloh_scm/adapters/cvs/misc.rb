module OhlohScm::Adapters
	class CvsAdapter
		# Returns an array of file and directory names from the remote server.
		# Directory names will end with a trailing '/' character.
		#
		# Directories named "CVSROOT" are always ignored, and thus never returned.
		#
		# An empty array means that the call succeeded, but the remote directory is empty.
		# A nil result means that the call failed and the remote server could not be queried.
		def ls(path=nil)
			path = File.join(@module_name, path.to_s)

			cmd = "cvsnt -q -d #{url} ls -e '#{path}'"

      ensure_host_key

			stdout, stderr = run_with_err(cmd)

			files = []
			stdout.each_line do |s|
				s.strip!
				s = $1 + '/' if s =~ /^D\/(.*)\/\/\/\/$/
				s = $1 if s =~ /^\/(.*)\/.*\/.*\/.*\/$/
				next if s == "CVSROOT/"
				files << s if s and s.length > 0
			end

			# Some of the cvs 'errors' are just harmless problems with some directories.
			# If we recognize all the error messages, then nothing is really wrong.
			# If some error messages go unhandled, then there really is an error.
			stderr.each_line do |s|
				s.strip!
				error_handled = false

				ignored_error_messages = [
					/Listing modules on server/,
					/Listing module: #{Regexp.escape(path.to_s)}/,
					/-m wrapper option is not supported remotely; ignored/,
					/cannot open directory .* No such file or directory/,
					/ignoring module/,
          /skipping directory/,
          /existing repository .* does not match/,
          /nothing known about/,

          # The signal 11 error should not really be ignored, but many CVS servers
          # including dev.eclipse.org return it at the end of every ls.
          /Terminated with fatal signal 11/
				]

				if s.length == 0
					error_handled = true
				elsif s =~ /cvs server: New directory `(#{Regexp.escape(path.to_s)}\/)?(.*)' -- ignored/
					files << "#{$2}/"
					error_handled = true
				end

				ignored_error_messages.each do |m|
					error_handled = true if s =~ m
				end

				logger.warn {	"'#{cmd}' resulted in unhandled error '#{s}'"	} unless error_handled
				return nil unless error_handled
			end

			files.sort
		end

		def log(most_recent_token=nil)
      ensure_host_key
			run "cvsnt -d #{self.url} rlog #{opt_branch} #{opt_time(most_recent_token)} '#{self.module_name}' | #{ string_encoder }"
		end

		def checkout(r, local_directory)
			opt_D = r.token ? "-D'#{r.token}Z'" : ""

      ensure_host_key
			if FileTest.exists?(local_directory + '/CVS/Root')
				# We already have a local enlistment, so do a quick update.
				if r.directories.size > 0
					build_ordered_directory_list(r.directories).each do |d|
						if d.length == 0
							run "cd #{local_directory} && cvsnt update -d -l -C #{opt_D} ."
						else
							run "cd #{local_directory} && cvsnt update -d -l -C #{opt_D} '#{d}'"
						end
					end
				else
					# Brute force: get all updates
					logger.warn("Revision #{r.token} did not contain any directories. Using brute force update of entire module.")
					run "cd #{local_directory} && cvsnt update -d -R -C #{opt_D}"
				end
			else
				# We do not have a local enlistment, so do a slow checkout to create one.
				# Silly cvsnt won't accept an absolute path. We'll have to play some games and cd to the parent directory.
				parent_path, checkout_dir = File.split(local_directory)
				FileUtils.mkdir_p(parent_path) unless FileTest.exist?(parent_path)
				run "cd #{parent_path} && cvsnt -d #{self.url} checkout #{opt_D} -A -d'#{checkout_dir}' '#{self.module_name}'"
			end
		end

		# A revision can contain an arbitrary collection of directories.
		# We need to ensure that for every directory we want to fetch, we also have its parent directories.
		def build_ordered_directory_list(directories)
			# Integration Test Limitation
			# cvsnt has problems with absolute path names, so we are stuck with
			# using cvs modules that are only a single directory deep when testing.
			# We'll check if the url begins with '/' to detect an integration test,
			# then return an empty string (ie, the default root directory) if so.
			return [''] if self.url =~ /^\//

				list = []
			directories.collect{ |a| trim_directory(a.to_s).to_s }.each do |d|
				# We always ignore Attic directories, which just contain deleted files
				# Update the parent directory of the Attic instead.
				if d =~ /^(.*)Attic$/
					d = $1
					d = d[0..-2] if d.length > 0 and d[-1,1]=='/'
				end

				unless list.include? d
					list << d
					# We also need to include every parent directory of the directory
					# we are interested in, all the way up to the root.
					while d.rindex('/') and d.rindex('/') > 0 do
						d = d[0..(d.rindex('/')-1)]
						if list.include? d
							break
						else
							list << d
						end
					end
				end
			end
			# Sort the list by length because we need to update parent directories before children
			list.sort! { |a,b| a.length <=> b.length }
		end

		def trim_directory(d)
			# If we are connecting to a remote server (basically anytime we are not
			# running the integration test) then we need to create a relative path
			# by trimming the prefix from the directory.
			# The prefix can be determined by examining the url and the module name.
			# For example, if url = ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle'
			# and module = 'contrib', then the directory prefix = '/cvsroot/moodle/contrib/'
			if root
				d[root.length..-1]
			else
				d # If not remote, just leave the directory name as-is
			end
		end

		def root
			"#{$3}/#{self.module_name}/" if self.url =~ /^:(pserver|ext):.*@[^:]+:(\d+)?(\/.*)$/
		end

		def opt_branch
			if branch_name != nil and branch_name.length > 0 and branch_name != 'HEAD'
		"-r'#{branch_name}'"
			else
		"-b -r1:"
			end
		end

    # returns the host this adapter is connecting to
    def host
      @host ||= begin
        self.url =~ /@([^:]*):/
        $1
      end
    end

    # returns the protocol this adapter connects with
    def protocol
      @protocol ||= case self.url
                    when /^:pserver/ then :pserver
                    when /^:ext/ then :ext
                    end
    end

    # using :ext (ssh) protocol might trigger ssh to confirm accepting the host's
    # ssh key. This causes the UI to hang asking for manual confirmation. To avoid
    # this we pre-populate the ~/.ssh/known_hosts file with the host's key.
    def ensure_host_key
      if self.protocol == :ext
        ensure_key_file = File.dirname(__FILE__) + "/../../../../bin/ensure_key"
        cmd = "#{ensure_key_file} '#{ self.host }'"
			  stdout, stderr = run_with_err(cmd)
      end
    end

    def tags
      tag_strings = `cvs -Q -d #{ url } rlog -h #{ module_name }| awk -F"[.:]" '/^\\t/&&$(NF-1)!=0'`.split(/\n/)
      tags_and_revs = tag_strings.map do |tag_string|
        tag_name, version = tag_string.split(':')
        [tag_name.gsub(/\t/, ''), version.strip]
      end

      Hash[tags_and_revs]
    end
	end
end
