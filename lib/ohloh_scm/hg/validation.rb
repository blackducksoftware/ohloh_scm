# frozen_string_literal: true

module OhlohScm
  module Hg
    class Validation < OhlohScm::Validation
      private

      def validate_server_connection
        msg = "The server did not respond to the 'hg id' command. Is the URL correct?"
        @errors << [:failed, msg] unless status.exist?
      end

      def public_url_regex
        %r{^(http|https)://(\w+@)?[\w\-.]+(:\d+)?/[\w\-./~+]*$}
      end
    end
  end
end
