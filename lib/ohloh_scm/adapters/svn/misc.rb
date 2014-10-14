require 'open-uri'

module OhlohScm::Adapters
	class SvnAdapter < AbstractAdapter
		# Converts an URL of form file://local/path to simply /local/path.
		def path
			case url
			when /^file:\/\/(.*)/
				$1
			when /^svn\+ssh:\/\/([^\/]+)(\/.+)/
				$2
			end
		end

		def hostname
			$1 if url =~ /^svn\+ssh:\/\/([^\/]+)(\/.+)/
		end

		# Does some simple searching through the server's directory tree for a
		# good canditate for the trunk. Basically, we are looking for a trunk
		# in order to avoid the heavy lifting of processing all the branches and tags.
		#
		# There are two simple rules to the search:
		#  (1) If the current directory contains a subdirectory named 'trunk', go there.
		#  (2) If the current directory is empty except for a single subdirectory, go there.
		# Repeat until neither rule is satisfied.
		#
		# The url and branch_name of this object will be updated with the selected location.
		# The url will be unmodified if there is a problem connecting to the server.
		def restrict_url_to_trunk
			return self.url if self.url =~ /\/trunk\/?$/

			list = ls
			return self.url unless list

			if list.include? 'trunk/'
				self.url = File.join(self.url, 'trunk')
				self.branch_name = File.join(self.branch_name, 'trunk')
			elsif list.size == 1 and list.first[-1..-1] == '/'
				self.url = File.join(self.url, list.first[0..-2])
				self.branch_name = File.join(self.branch_name, list.first[0..-2])
				return restrict_url_to_trunk
			end
			self.url
		end

		# It appears that the default URI encoder does not encode some characters.
		# This fixes it for us.
		def self.uri_encode(uri)
			URI.encode(uri,/#{URI::UNSAFE}|[\[\]';\? ]/) # Add [ ] ' ; ? and space
		end

		def exist?
			begin
				!!(head_token)
			rescue
				logger.debug { $! }
				false
			end
		end

		def info(path=nil, revision=final_token || 'HEAD')
			@info ||= {}
			uri = if path
							File.join(root, branch_name.to_s, path)
						else
							url
						end
			@info[[path, revision]] ||= run "svn info --trust-server-cert --non-interactive -r #{revision} #{opt_auth} '#{SvnAdapter.uri_encode(uri)}@#{revision}'"
		end

		def root
			$1 if self.info =~ /^Repository Root: (.+)$/
		end

		def uuid
			$1 if self.info =~ /^Repository UUID: (.+)$/
		end

		# Returns an array of file and directory names.
		# Directory names will end with a trailing '/' character.
		# Directories named 'CVSROOT' are always ignored and never returned.
		# An empty array means that the call succeeded, but the remote directory is empty.
		# A nil result means that the call failed and the remote server could not be queried.
		def ls(path=nil, revision=final_token || 'HEAD')
			begin
				stdout = run "svn ls --trust-server-cert --non-interactive -r #{revision} #{opt_auth} '#{SvnAdapter.uri_encode(File.join(root, branch_name.to_s, path.to_s))}@#{revision}'"
			rescue
				return nil
			end

			files = []
			stdout.each_line do |s|
				s.chomp!
				files << s if s.length > 0 and s != 'CVSROOT/'
			end
			files.sort
		end

		def node_kind(path=nil, revision=final_token || 'HEAD')
			$1 if self.info(path, revision) =~ /Node Kind: (\w+)\W/
		end

		def is_directory?(path=nil, revision=final_token || 'HEAD')
			begin
				return node_kind(path, revision) == 'directory'
			rescue Exception
				if $!.message =~ /svn: E200009: Could not display info for all targets because some targets don't exist/
					return false
				else
					raise
				end
			end
		end

		def checkout(rev, dest_dir)
			FileUtils.mkdir_p(File.dirname(dest_dir)) unless FileTest.exist?(File.dirname(dest_dir))
			run "svn checkout --trust-server-cert --non-interactive -r #{rev.token} '#{SvnAdapter.uri_encode(self.url)}@#{rev.token}' '#{dest_dir}' --ignore-externals #{opt_auth}"
		end

		def export(dest_dir, commit_id = final_token || 'HEAD')
			FileUtils.mkdir_p(File.dirname(dest_dir)) unless FileTest.exist?(File.dirname(dest_dir))
			run "svn export --trust-server-cert --non-interactive --ignore-externals --force -r #{commit_id} '#{SvnAdapter.uri_encode(File.join(root, branch_name.to_s))}' '#{dest_dir}'"
		end

		def ls_tree(token)
			run("svn ls --trust-server-cert --non-interactive -R -r #{token} '#{SvnAdapter.uri_encode(File.join(root, branch_name.to_s))}@#{token}'").split("\n")
		end

		def opt_auth
			opt_password = ""
			opt_password = "--username='#{self.username}' --password='#{self.password}'" if self.username && self.username != ''
			" #{opt_password} --no-auth-cache "
		end

    def self.has_conflicts?(working_copy_url)
      system("cd '#{ working_copy_url }' && svn status | grep 'Summary of conflicts'")
    end
	end
end
