# frozen_string_literal: true

module OhlohScm
  module Svn
    class Validation < OhlohScm::Validation
      private

      def validate_server_connection
        @errors ||= []
        @errors << head_token_error
        @errors << url_error
        @errors.compact!
      rescue StandardError
        @errors << server_connection_error
      end

      def public_url_regex
        /^(http|https|svn):\/\/[A-Za-z0-9_\-.]+(:\d+)?(\/[A-Za-z0-9_\-.\/+%^~ ]*)?$/
      end

      # Subversion usernames have been relaxed from the abstract rules.
      # We allow email names as usernames.
      def username_errors
        return if scm.username.to_s.empty?

        if scm.username.length > 32
          [:username, 'The username must not be longer than 32 characters.']
        elsif !scm.username.match?(/^\w[\w@.+\-]*$/)
          [:username, 'The username contains illegal characters.']
        end
      end

      def head_token_error
        return if activity.head_token

        [:failed, "The server did not respond to a 'svn info' command. Is the URL correct?"]
      end

      def url_error
        root_path = activity.root

        if scm.url[0..root_path.length - 1] != root_path
          [:failed, "The URL did not match the Subversion root #{root_path}. Is the URL correct?"]
        elsif scm.recalc_branch_name && activity.ls.nil?
          [:failed, "The server did not respond to a 'svn ls' command. Is the URL correct?"]
        end
      end

      def server_connection_error
        logger.error { $ERROR_INFO.inspect }
        [:failed,
         'An error occured connecting to the server. Check the URL, username, and password.']
      end
    end
  end
end
