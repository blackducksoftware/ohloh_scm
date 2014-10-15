module OhlohScm::Adapters
	class DarcsAdapter < AbstractAdapter
		def self.url_regex
			/^((http|https|ssh|file):\/\/((\w+@)?[A-Za-z0-9_\-\.]+(:\d+)?\/)?)?[A-Za-z0-9_\-\.\/\~\+]*$/
		end

		def self.public_url_regex
			/^(http|https):\/\/(\w+@)?[A-Za-z0-9_\-\.]+(:\d+)?\/[A-Za-z0-9_\-\.\/\~\+]*$/
		end

		def validate_server_connection
			return unless valid?
			@errors << [:failed, "The server did not respond to the 'darcs id' command. Is the URL correct?"] unless self.exist?
		end

		def guess_forge
			u = @url =~ /:\/\/(.*\.?darcs\.)?([^\/^:]+)(:\d+)?\// ? $2 : nil
			case u
			when /(sourceforge\.net$)/
				$1
			else
				u
			end
		end
	end
end
