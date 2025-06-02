# frozen_string_literal: true

module OhlohScm
  module Cvs
    class Activity < OhlohScm::Activity
      def tags
        cmd = "cvs -Q -d #{url} rlog -h #{scm.branch_name} | awk -F\"[.:]\" '/^\\t/&&$(NF-1)!=0'"
        tag_strings = run(cmd).split("\n")
        tag_strings.map do |tag_string|
          tag_name, version = tag_string.split(':')
          [tag_name.delete("\t"), version.strip]
        end
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def commits(opts = {})
        after = opts[:after]
        result = []

        open_log_file(opts) do |io|
          result = OhlohScm::CvsParser.parse(io)
        end

        # Git converter needs a backpointer to the scm for each commit
        result.each { |c| c.scm = scm }

        return result if result.empty? # Nothing found; we're done here.
        return result if after.to_s == '' # We requested everything, so just return everything.

        # We must now remove any duplicates caused by timestamp fudge factors,
        # and only return commits with timestamp > after.

        # If the first commit is newer than after,
        # then the whole list is new and we can simply return.
        return result if parse_time(result.first.token) > parse_time(after)

        # Walk the list of commits to find the first new one, throwing away all of the old ones.

        # I want to string-compare timestamps without converting to dates objects.
        # Some CVS servers print dates as 2006/01/02 03:04:05, others as 2006-01-02 03:04:05.
        # To work around this, we'll build a regex that matches either date format.
        re = Regexp.new(after.gsub(/[\/-]/, '.'))

        result.each_index do |i|
          next unless result[i].token&.match?(re) # We found the match for after
          return [] if i == result.size - 1 # There aren't any new commits.

          return result[i + 1..]
        end

        # Something bad is going on: 'after' does not match any timestamp in the rlog.
        # This is very rare, but it can happen.
        #
        # Often this means that the *last* time we ran commits(), there was some kind of
        # undetected problem (CVS was in an intermediate state?) so the list of timestamps we
        # calculated last time does not match the list of timestamps we calculated this time.
        #
        # There's no work around for this condition here in the code, but there are some things
        # you can try manually to fix the problem. Typically, you can try throwing way the
        # commit associated with 'after' and fetching it again (git reset --hard HEAD^).
        raise "token '#{after}' not found in rlog."
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def export_tag(dest_dir, tag_name = 'HEAD')
        run "cvsnt -d #{url} export -d'#{dest_dir}' -r #{tag_name} '#{scm.branch_name}'"
      end

      # using :ext (ssh) protocol might trigger ssh to confirm accepting the host's
      # ssh key. This causes the UI to hang asking for manual confirmation. To avoid
      # this we pre-populate the ~/.ssh/known_hosts file with the host's key.
      def ensure_host_key
        return if protocol != :ext

        ensure_key_file = "#{File.dirname(__FILE__)}/../../../../bin/ensure_key"
        cmd = "#{ensure_key_file} '#{host}'"
        run_with_err(cmd)
      end

      private

      # Gets the rlog of the repository and saves it in a temporary file.
      # If you pass a timestamp token, then only commits after the timestamp will be returned.
      #
      # Warning!
      #
      # CVS servers are apparently unreliable when you truncate
      # the log by timestamp -- perhaps round-off error?
      # In any case, to be sure not to miss any commits,
      # this method subtracts 10 seconds from the provided timestamp.
      # This means that the returned log might actually contain a few revisions
      # that predate the requested time.
      # That's better than missing revisions completely! Just be sure to check for duplicates.
      def open_log_file(opts = {}, &block)
        ensure_host_key
        status.lock?
        run "cvsnt -d #{url} rlog #{opt_branch} #{opt_time(opts[:after])} '#{scm.branch_name}' " \
            "| #{string_encoder_path} > #{rlog_filename}"
        File.open(rlog_filename, 'r', &block)
      ensure
        FileUtils.rm_f(rlog_filename)
      end

      def opt_time(after = nil)
        return '' unless after

        most_recent_time = parse_time(after) - 10
        # rubocop:disable Layout/LineLength
        " -d '#{most_recent_time.strftime('%Y-%m-%d %H:%M:%S')}Z<#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S')}Z' "
        # rubocop:enable Layout/LineLength
      end

      def rlog_filename
        File.join(temp_folder, "#{(url + scm.branch_name.to_s).gsub(/\W/, '')}.rlog")
      end

      # Converts a CVS time string to a Ruby Time object
      def parse_time(token)
        case token
        when /(\d\d\d\d).(\d\d).(\d\d) (\d\d):(\d\d):(\d\d)/
          Time.gm(Regexp.last_match(1).to_i, Regexp.last_match(2).to_i, Regexp.last_match(3).to_i,
                  Regexp.last_match(4).to_i, Regexp.last_match(5).to_i, Regexp.last_match(6).to_i)
        end
      end

      # returns the host this adapter is connecting to
      def host
        @host ||= begin
          url =~ /@([^:]*):/
          Regexp.last_match(1)
        end
      end

      # returns the protocol this adapter connects with
      def protocol
        @protocol ||= case url
                      when /^:pserver/ then :pserver
                      when /^:ext/ then :ext
                      end
      end

      def opt_branch
        '-b -r1:'
      end
    end
  end
end
