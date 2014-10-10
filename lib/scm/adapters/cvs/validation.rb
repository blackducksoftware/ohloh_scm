module Scm::Adapters
	class CvsAdapter
		def self.url_regex
			/^(:(pserver|ext):[\w\-\+\_]*(:[\w\-\+\_]*)?@[A-Za-z0-9_\-\+\.]+:[0-9]*)?\/[A-Za-z0-9_\-\+\.\/]*$/
		end

		def self.public_url_regex
			/^:(pserver|ext):[\w\-\+\_]*(:[\w\-\+\_]*)?@[A-Za-z0-9_\-\+\.]+:[0-9]*\/[A-Za-z0-9_\-\+\.\/]*$/
		end

		def validate
			super
			@errors << validate_module_name
			@errors.compact!
		end

		def validate_module_name
			return [:module_name, "The module name can't be blank."] if @module_name.to_s.length == 0
			return [:module_name, "The module name must not be longer than 120 characters."] unless @module_name.length <= 120
			return [:module_name, "The module name may contain only letters, numbers, spaces, and the special characters '_', '-', '+', '/', and '.'"] unless @module_name =~ /^[A-Za-z0-9_\-\+\.\/\ ]+$/
		end

		def normalize
			super
			@module_name = @module_name.strip if @module_name

			# Some CVS forges publish an URL which is actually a symlink, which causes CVSNT to crash.
			# For some forges, we can work around this by using an alternate directory.
			case guess_forge
			when 'java.net', 'netbeans.org'
				@url.gsub!(/:\/cvs\/?$/, ':/shared/data/ccvs/repository')
			when 'gna.org'
				@url.gsub!(/:\/cvs\b/, ':/var/cvs')
			end

			sync_pserver_username_password

			self
		end

		# This bit of code patches up any inconsistencies that may arise because there
		# is both a @password attribute and a password embedded in the :pserver: url.
		# This method guarantees that they are both the same.
		#
		# It's assumed that if the user specified a @password attribute, then that is
		# the preferred value and it should take precedence over any password found
		# in the :pserver: url.
		#
		# If the user did not specify a @password attribute, then the value
		# found in the :pserver: url is assigned to both.
		def sync_pserver_username_password
			# Do nothing unless pserver connection string is well-formed.
			return unless self.url =~ /:pserver:([\w\-\_]*)(:([\w\-\_]*))?@(.*)$/

			pserver_username = $1
			pserver_password = $3
			pserver_remainder = $4

			@username = pserver_username if @username.to_s == ''
			@password = pserver_password if @password.to_s == ''

			self.url = ":pserver:#{@username}:#{password}@#{pserver_remainder}"
		end

		def validate_server_connection
			return unless valid?
			if ls.nil?
				@errors << [:failed, "The cvs server did not respond to an 'ls' command. Are the URL and module name correct?"]
			end
		rescue CommandNotSupportedException
		  if !log_check
			@errors << [:failed, "The cvs server did not respond to an 'ls' or 'rlog' command. Are the URL and module name correct?"]
		  end
		end

		# Based on the URL, take a guess about which forge this code is hosted on.
		def guess_forge
			@url =~ /.*(pserver|ext).*@(([^\.]+\.)?(cvs|dev)\.)?([^:]+):\//i ? $5.downcase : nil
		end
	end
end
