# frozen_string_literal: true

module OhlohScm
  module Cvs
    class Validation < OhlohScm::Validation
      include OhlohScm::System

      private

      def validate_server_connection
        return if ls

        @errors << [:failed, "The cvs server did not respond to an 'ls' command.
                  Are the URL and branch name correct?"]
      end

      def branch_name_errors
        if scm.branch_name.to_s.empty?
          [:branch_name, "The branch name can't be blank."]
        elsif scm.branch_name.length > 200
          [:branch_name, 'The branch name must not be longer than 200 characters.']
        elsif !scm.branch_name.match?(/^[\w\-+.\/\ ]+$/)
          [:branch_name, "The branch name may contain only letters,
          numbers, spaces, and the special characters '_', '-', '+', '/', and '.'"]
        end
      end

      def public_url_regex
        /^:(pserver|ext):[\w\-+_]*(:[\w\-+_]*)?@[\w\-+.]+:[0-9]*\/[\w\-+.\/]*$/
      end

      # Returns an array of file and directory names from the remote server.
      # Directory names will end with a trailing '/' character.
      #
      # Directories named "CVSROOT" are always ignored, and thus never returned.
      #
      # An empty array means that the call succeeded, but the remote directory is empty.
      # A nil result means that the call failed and the remote server could not be queried.
      def ls(path = nil)
        path = File.join(scm.branch_name, path.to_s)

        cmd = "cvsnt -q -d #{scm.url} ls -e '#{path}'"

        activity.ensure_host_key

        stdout, stderr = run_with_err(cmd)
        files = get_filenames(stdout)

        error_handled = handle_error(stderr, files, path, cmd)
        return unless error_handled

        files.sort
      end

      def get_filenames(output)
        files = []
        output.each_line do |s|
          s.strip!
          s = "#{Regexp.last_match(1)}/" if s =~ /^D\/(.*)\/\/\/\/$/
          s = Regexp.last_match(1) if s =~ /^\/(.*)\/.*\/.*\/.*\/$/
          next if s == 'CVSROOT/'

          files << s if s && !s.empty?
        end
        files
      end

      # rubocop:disable Metrics/MethodLength
      def handle_error(stderr, files, path, cmd)
        # Some of the cvs 'errors' are just harmless problems with some directories.
        # If we recognize all the error messages, then nothing is really wrong.
        # If some error messages go unhandled, then there really is an error.
        stderr.each_line do |error|
          error.strip!
          error_handled = error.empty?

          if error =~ /cvs server: New directory `(#{Regexp.escape(path.to_s)}\/)?(.*)' -- ignored/
            files << "#{Regexp.last_match(2)}/"
            error_handled = true
          end

          ignored_error_handled(error, path)
          logger.warn { "'#{cmd}' resulted in unhandled error '#{error}'" } unless error_handled
          break unless error_handled
        end
      end
      # rubocop:enable Metrics/MethodLength

      def ignored_error_handled(error, path)
        ignored_error_messages = [
          /Listing modules on server/, /Listing module: #{Regexp.escape(path.to_s)}/,
          /-m wrapper option is not supported remotely; ignored/,
          /cannot open directory .* No such file or directory/,
          /ignoring module/, /skipping directory/,
          /existing repository .* does not match/,
          /nothing known about/,

          # The signal 11 error should not really be ignored, but many CVS servers
          # including dev.eclipse.org return it at the end of every ls.
          /Terminated with fatal signal 11/
        ]
        ignored_error_messages.any? { |msg| error.match?(msg) }
      end
    end
  end
end
