module Scm::Adapters
	class BzrAdapter < AbstractAdapter

		def pull(from, &block)
			raise ArgumentError.new("Cannot pull from #{from.inspect}") unless from.is_a?(BzrAdapter)
			logger.info { "Pulling #{from.url}" }

			yield(0,1) if block_given? # Progress bar callback

			unless self.exist?
				run "mkdir -p '#{self.url}'"
				run "rm -rf '#{self.url}'"
				run "bzr branch '#{from.url}' '#{self.url}'"
        clean_up_disk
			else
				run "cd '#{self.url}' && bzr revert && bzr pull --overwrite '#{from.url}'"
			end

			yield(1,1) if block_given? # Progress bar callback
		end

    def clean_up_disk
      # Usually a `bzr upgrade` is unnecessary, but it's fatal to miss it when
      # required. Because I don't know how to detect in advance whether we
      # actually need it, we play it safe and always upgrade.
      #
      # Unfortunately, not only can we not know whether it is required,
      # but the command fails and raises when the upgrade is not required.

      begin
			  run "cd '#{self.url}' && bzr upgrade"
      rescue RuntimeError => e
        raise unless e.message =~ /already at the most recent format/
      end
    end

	end
end
