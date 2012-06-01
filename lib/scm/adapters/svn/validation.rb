module Scm::Adapters
	class SvnAdapter < AbstractAdapter
		def self.url_regex
			/^(file|http|https|svn):\/\/(\/)?[A-Za-z0-9_\-\.]+(:\d+)?(\/[A-Za-z0-9_\-\.\/\+%^~ ]*)?$/
		end

		def self.public_url_regex
			/^(http|https|svn):\/\/[A-Za-z0-9_\-\.]+(:\d+)?(\/[A-Za-z0-9_\-\.\/\+%^~ ]*)?$/
		end

		def normalize
			super
			@url = path_to_file_url(@url)
			@url = force_https_if_sourceforge(@url)
			@branch_name = @branch_name[0..-2] if @branch_name && @branch_name[-1..-1] == '/'
			self
		end

		# Subversion usernames have been relaxed from the abstract rules. We allow email names as usernames.
		def validate_username
			return nil unless @username
			return nil if @username.length == 0
			return [:username, "The username must not be longer than 32 characters."] unless @username.length <= 32
			return [:username, "The username contains illegal characters."] unless @username =~ /^\w[\w@\.\+\-]*$/
		end

		# If the URL is a simple directory path, make sure it is prefixed by file://
		def path_to_file_url(path)
			return nil if path.empty?
			url =~ /:\/\// ? url : 'file://' + File.expand_path(path)
		end

		def force_https_if_sourceforge(url)
			# SourceForge requires https for svnsync
			url =~ /http(:\/\/.*svn\.sourceforge\.net.*)/ ? "https#{$1}" : url
		end

		def validate_server_connection
			return unless valid?
			begin
				if head_token.nil?
					@errors << [:failed, "The server did not respond to a 'svn info' command. Is the URL correct?"]
				elsif self.url[0..root.length-1] != root
					@errors << [:failed, "The URL did not match the Subversion root #{root}. Is the URL correct?"]
				elsif recalc_branch_name && ls.nil?
					@errors << [:failed, "The server did not respond to a 'svn ls' command. Is the URL correct?"]
				end
			rescue
				logger.error { $!.inspect }
				@errors << [:failed, "An error occured connecting to the server. Check the URL, username, and password."]
			end
		end

		# From the given URL, determine which part of it is the root and which part of it is the branch_name.
		# The current branch_name is overwritten.
		def recalc_branch_name
			@branch_name = @url ? @url[root.length..-1] : @branch_name
			@branch_name = @branch_name[0..-2] if @branch_name[-1..-1] == '/'
			@branch_name
		end

		def guess_forge
			u = @url =~ /:\/\/(.*\.?svn\.)?([^\/^:]+)(:\d+)?(\/|$)/ ? $2 : nil
			case u
			when /(googlecode\.com$)/, /(tigris\.org$)/, /(sunsource\.net$)/, /(java\.net$)/,
				/(openoffice\.org$)/, /(netbeans\.org$)/, /(dev2dev\.bea\.com$)/, /(rubyforge\.org$)/
				$1
			else
				u
			end
		end
	end
end
