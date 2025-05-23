# frozen_string_literal: true

module OhlohScm
  module Cvs
    class Scm < OhlohScm::Scm
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:disable Metrics/PerceivedComplexity
      def checkout(rev, local_directory)
        opt_d = rev.token ? "-D'#{rev.token}Z'" : ''

        activity.ensure_host_key
        if File.exist?(local_directory + '/CVS/Root')
          # We already have a local enlistment, so do a quick update.
          if !rev.directories.empty?
            build_ordered_directory_list(rev.directories).each do |d|
              if d.empty?
                run "cd #{local_directory} && cvsnt update -d -l -C #{opt_d} ."
              else
                run "cd #{local_directory} && cvsnt update -d -l -C #{opt_d} '#{d}'"
              end
            end
          else
            # Brute force: get all updates
            logger.warn("Revision #{rev.token} did not contain any directories.
            Using brute force update of entire module.")
            run "cd #{local_directory} && cvsnt update -d -R -C #{opt_d}"
          end
        else
          # We do not have a local enlistment, so do a slow checkout to create one.
          # Silly cvsnt won't accept an absolute path.
          # We'll have to play some games and cd to the parent directory.
          parent_path, checkout_dir = File.split(local_directory)
          FileUtils.mkdir_p(parent_path) unless File.exist?(parent_path)
          run "cd #{parent_path} &&
          cvsnt -d #{url} checkout #{opt_d} -A -d'#{checkout_dir}' '#{branch_name}'"
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:enable Metrics/PerceivedComplexity

      def normalize
        # Some CVS forges publish an URL which is actually a symlink, which causes CVSNT to crash.
        # For some forges, we can work around this by using an alternate directory.
        case guess_forge
        when 'java.net', 'netbeans.org'
          url.gsub!(/:\/cvs\/?$/, ':/shared/data/ccvs/repository')
        when 'gna.org'
          url.gsub!(/:\/cvs\b/, ':/var/cvs')
        end

        sync_pserver_username_password

        self
      end

      private

      # A revision can contain an arbitrary collection of directories.
      # We need to ensure that for every directory we want to fetch,
      # we also have its parent directories.
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def build_ordered_directory_list(directories)
        # Integration Test Limitation
        # cvsnt has problems with absolute path names, so we are stuck with
        # using cvs modules that are only a single directory deep when testing.
        # We'll check if the url begins with '/' to detect an integration test,
        # then return an empty string (ie, the default root directory) if so.
        return [''] if /^\//.match?(url)

        list = []
        directories = directories.collect { |a| trim_directory(a.to_s).to_s }
        directories.each do |d|
          # We always ignore Attic directories, which just contain deleted files
          # Update the parent directory of the Attic instead.
          if d =~ /^(.*)Attic$/
            d = Regexp.last_match(1)
            d = d[0..-2] if !d.empty? && (d[-1, 1] == '/')
          end

          next if list.include? d

          list << d
          # We also need to include every parent directory of the directory
          # we are interested in, all the way up to the root.
          while d.rindex('/')&.positive?
            d = File.dirname(d)
            break if list.include? d

            list << d
          end
        end

        # Sort the list by length because we need to update parent directories before children
        list.sort! { |a, b| a.length <=> b.length }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      def trim_directory(dir)
        # If we are connecting to a remote server (basically anytime we are not
        # running the integration test) then we need to create a relative path
        # by trimming the prefix from the directory.
        # The prefix can be determined by examining the url and the module name.
        # For example, if url = ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle'
        # and module = 'contrib', then the directory prefix = '/cvsroot/moodle/contrib/'
        # If not remote, just leave the directory name as-is
        root ? dir[root.length..-1] : dir
      end

      def root
        return unless url =~ /^:(pserver|ext):.*@[^:]+:(\d+)?(\/.*)$/

        "#{Regexp.last_match(3)}/#{branch_name}/"
      end

      # This bit of code patches up any inconsistencies that may arise because there
      # is both a @password attribute and a password embedded in the :pserver: url.
      # This method guarantees that they are both the same.
      #
      # It's assumed that if the user specified a @password attribute, then that is
      # the preferred value and it should take precedence over any password found
      # in the :pserver: url.
      #
      # If the user did not specify a @password attribute, then the value
      # found in the :pserver: url is assigned to both.
      def sync_pserver_username_password
        # Do nothing unless pserver connection string is well-formed.
        return unless url =~ /:pserver:([\w\-\_]*)(:([\w\-\_]*))?@(.*)$/

        pserver_username = Regexp.last_match(1)
        pserver_password = Regexp.last_match(3)
        pserver_remainder = Regexp.last_match(4)

        @username = pserver_username if @username.to_s.empty?
        @password = pserver_password if @password.to_s.empty?

        @url = ":pserver:#{@username}:#{password}@#{pserver_remainder}"
      end

      # Based on the URL, take a guess about which forge this code is hosted on.
      def guess_forge
        return unless url =~ /.*(pserver|ext).*@(([^\.]+\.)?(cvs|dev)\.)?([^:]+):\//i

        Regexp.last_match(5).downcase
      end
    end
  end
end
