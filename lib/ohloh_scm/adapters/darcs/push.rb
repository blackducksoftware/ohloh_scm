module OhlohScm::Adapters
	class DarcsAdapter < AbstractAdapter

		def push(to, &block)
			raise ArgumentError.new("Cannot push to #{to.inspect}") unless to.is_a?(DarcsAdapter)
			logger.info { "Pushing to #{to.url}" }

			yield(0,1) if block_given? # Progress bar callback

			unless to.exist?
				if to.local?
					# Create a new repo on the same local machine. Just use existing pull code in reverse.
					to.pull(self)
				else
					run "cd '#{self.url}' && darcs put #{to.hostname}:#{to.path}"
				end
			else
				run "cd '#{self.url}' && darcs push -a '#{to.url}'"
			end

			yield(1,1) if block_given? # Progress bar callback
		end

		def local?
			return true if hostname == Socket.gethostname
			return true if url =~ /^file:\/\//
			return true if url !~ /:/
			false
		end

		def hostname
			$1 if url =~ /^ssh:\/\/([^\/]+)/
		end

		def path
			case url
			when /^file:\/\/(.+)$/
				$1
			when /^ssh:\/\/[^\/]+(\/.+)$/
				$1
			when /^[^:]*$/
				url
			end
		end

		def darcs_path
			path && File.join(path, '.darcs')
		end
	end
end
