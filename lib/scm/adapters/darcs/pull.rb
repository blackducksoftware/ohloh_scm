module Scm::Adapters
	class DarcsAdapter < AbstractAdapter

		def pull(from, &block)
			raise ArgumentError.new("Cannot pull from #{from.inspect}") unless from.is_a?(DarcsAdapter)
			logger.info { "Pulling #{from.url}" }

			yield(0,1) if block_given? # Progress bar callback

			unless self.exist?
				run "mkdir -p '#{self.url}'"
				run "rm -rf '#{self.url}'"
				run "darcs clone -U '#{from.url}' '#{self.url}'"
			else
				run "cd '#{self.url}' && darcs revert --all && darcs pull -u -y '#{from.url}'"
			end

			yield(1,1) if block_given? # Progress bar callback
		end

	end
end
