# frozen_string_literal: true

module OhlohScm
  module Bzr
    class Scm < OhlohScm::Scm
      def pull(from, callback)
        callback.update(0, 1)

        if status.exist?
          run "cd '#{url}' && bzr revert && bzr pull --overwrite '#{from.url}'"
        else
          run "rm -rf '#{url}'"
          run "bzr branch '#{from.url}' '#{url}'"
        end

        callback.update(1, 1)
      end

      def vcs_path
        "#{url}/.bzr"
      end

      def checkout_files(_names)
        # Files are already checked out.
      end
    end
  end
end
