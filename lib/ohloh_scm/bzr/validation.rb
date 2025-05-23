# frozen_string_literal: true

module OhlohScm
  module Bzr
    class Validation < OhlohScm::Validation
      private

      def validate_server_connection
        msg = "The server did not respond to the 'bzr revno' command. Is the URL correct?"
        @errors << [:failed, msg] unless status.exist?
      end

      def public_url_regex
        %r{^(((http|https|bzr)://(\w+@)?[\w\-.]+(:\d+)?/)|(lp:[\w\-.~]))[\w\-./~+]*$}
      end
    end
  end
end
