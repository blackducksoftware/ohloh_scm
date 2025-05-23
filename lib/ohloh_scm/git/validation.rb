# frozen_string_literal: true

module OhlohScm
  module Git
    class Validation < OhlohScm::Validation
      private

      def validate_server_connection
        msg = "The server did not respond to the 'git-ls-remote' command. Is the URL correct?"
        @errors << [:failed, msg] unless status.exist?
      end

      def public_url_regex
        %r{^(http|https|git)://(\w+@)?[\w\-.]+(:\d+)?/[\w\-./~+]*$}
      end
    end
  end
end
