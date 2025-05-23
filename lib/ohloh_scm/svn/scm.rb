# frozen_string_literal: true

module OhlohScm
  module Svn
    class Scm < OhlohScm::Scm
      def normalize
        url = prefix_file_for_local_path(@url)
        @url = force_https_if_sourceforge(url)
        if branch_name
          clean_branch_name
        else
          @branch_name = recalc_branch_name
        end
        self
      end

      # From the given URL, determine which part of it is the root and
      # which part of it is the branch_name. The current branch_name is overwritten.
      def recalc_branch_name
        @branch_name = url ? url[activity.root.length..-1] : branch_name
      rescue RuntimeError => e
        pattern = /(svn:*is not a working copy|Unable to open an ra_local session to URL)/
        @branch_name = '' if e.message&.match?(pattern) # we have a file system
      ensure
        clean_branch_name
        branch_name
      end

      def accept_ssl_certificate_cmd
        File.expand_path('../../../.bin/accept_svn_ssl_certificate', __dir__)
      end

      # Does some simple searching through the server's directory tree for a
      # good canditate for the trunk. Basically, we are looking for a trunk
      # in order to avoid the heavy lifting of processing all the branches and tags.
      #
      # There are two simple rules to the search:
      #  (1) If the current directory contains a subdirectory named 'trunk', go there.
      #  (2) If the current directory is empty except for a single subdirectory, go there.
      # Repeat until neither rule is satisfied.
      #
      # The url and branch_name of this object will be updated with the selected location.
      # The url will be unmodified if there is a problem connecting to the server.
      def restrict_url_to_trunk
        return url if url.match?(%r{/trunk/?$})

        list = activity.ls
        return url unless list

        if list.include? 'trunk/'
          update_url_and_branch_with_trunk
        elsif list.size == 1 && list.first[-1..-1] == '/'
          update_url_and_branch_with_subdir(list)
          return restrict_url_to_trunk
        end
        url
      end

      private

      def update_url_and_branch_with_trunk
        @url = File.join(url, 'trunk')
        @branch_name = File.join(branch_name.to_s, 'trunk')
      end

      def update_url_and_branch_with_subdir(list)
        folder_name = list.first[0..-2]
        @url = File.join(url, folder_name)
        @branch_name = File.join(branch_name.to_s, folder_name)
      end

      def clean_branch_name
        return unless branch_name

        @branch_name.chop! if branch_name.to_s.end_with?('/')
      end

      def force_https_if_sourceforge(url)
        return url unless url =~ /http(:\/\/.*svn\.(sourceforge|code\.sf)\.net.*)/

        # SourceForge requires https for svnsync
        "https#{Regexp.last_match(1)}"
      end

      # If the URL is a simple directory path, make sure it is prefixed by file://
      def prefix_file_for_local_path(path)
        return if path.empty?

        %r{://}.match?(url) ? url : 'file://' + File.expand_path(path)
      end
    end
  end
end
