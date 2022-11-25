# frozen_string_literal: true

module OhlohScm
  module Bzr
    class Activity < OhlohScm::Activity
      # rubocop:disable Metrics/MethodLength
      def tags
        tag_strings.map do |tag_string|
          parse_tag_names_and_revision = tag_string.split(/\s+/)
          if parse_tag_names_and_revision.size > 1
            tag_name = parse_tag_names_and_revision[0..-2].join(' ')
            rev = parse_tag_names_and_revision.last
          else
            tag_name = parse_tag_names_and_revision.first
            rev = nil
          end
          next if rev == '?' || tag_name == '....'

          [tag_name, rev, Time.parse(time_string(rev))]
        end.compact
      end
      # rubocop:enable Metrics/MethodLength

      def export_tag(dest_dir, tag_name)
        run "cd '#{url}' && bzr export -r #{tag_name} #{dest_dir}"
      end

      def export(dest_dir, token = head_token)
        # Unlike other SCMs, Bzr doesn't simply place the contents into dest_dir.
        # It actually *creates* dest_dir. Since it should already exist at this point,
        # first we have to delete it.
        Dir.delete(dest_dir) if File.exist?(dest_dir)

        run "cd '#{url}' && bzr export --format=dir -r #{to_rev_param(token)} '#{dest_dir}'"
      end

      # Returns a list of shallow commits (i.e., the diffs are not populated).
      # Not including the diffs is meant to be a memory savings when
      # we encounter massive repositories.  If you need all commits
      # including diffs, you should use the each_commit() iterator,
      # which only holds one commit in memory at a time.
      def commits(opts = {})
        after = opts[:after]
        log = run("#{rev_list_command(opts)} | cat")
        a = OhlohScm::BzrXmlParser.parse(log)

        if after && (i = a.index { |commit| commit.token == after })
          a[(i + 1)..-1]
        else
          a
        end
      end

      # Return the list of commit tokens following +after+.
      def commit_tokens(opts = {})
        commits(opts).map(&:token)
      end

      # Return the number of commits in the repository following +after+.
      def commit_count(opts = {})
        commit_tokens(opts).size
      end

      def each_commit(opts = {})
        after = opts[:after]
        skip_commits = !after.nil? # Don't emit any commits until the 'after' resume point passes

        safe_open_log_file(opts) do |io|
          OhlohScm::BzrXmlParser.parse(io) do |commit|
            yield remove_directories(commit) if block_given? && !skip_commits
            skip_commits = false if commit.token == after
          end
        end
      end

      def head_token
        run("bzr log --limit 1 --show-id #{url} 2> /dev/null"\
            " | grep ^revision-id | cut -f2 -d' '").strip
      end

      def head
        verbose_commit(head_token)
      end

      def parent_tokens(commit)
        bzr_client.parent_tokens(commit.token)
      end

      def parents(commit)
        parent_tokens(commit).collect { |token| verbose_commit(token) }
      end

      def cat_file(commit, diff)
        cat(commit.token, diff.path)
      end

      def cat_file_parent(commit, diff)
        first_parent_token = parent_tokens(commit).first
        cat(first_parent_token, diff.path) if first_parent_token
      end

      def cleanup
        bzr_client.shutdown
      end

      private

      # Returns a single commit, including its diffs
      def verbose_commit(token)
        cmd = "cd '#{url}' && bzr xmllog --show-id -v --limit 1 -c #{to_rev_param(token)}"
        log = run(cmd)
        OhlohScm::BzrXmlParser.parse(log).first
      end

      def to_rev_param(rev = nil)
        case rev
        when nil
          1
        when Integer
          rev.to_s
        when /^\d+$/
          rev
        else
          "'revid:#{rev}'"
        end
      end

      def rev_list_command(opts = {})
        after = opts[:after]
        trunk_only = opts[:trunk_only] ? '--levels=1' : '--include-merges'
        "cd '#{url}' && bzr xmllog --show-id --forward #{trunk_only} -r #{to_rev_param(after)}.."
      end

      # Returns a file handle to the log.
      # In our standard, the log should include everything AFTER
      # +after+. However, bzr doesn't work that way; it returns
      # everything after and INCLUDING +after+. Therefore, consumers
      # of this file should check for and reject the duplicate commit.
      def safe_open_log_file(opts = {})
        return '' if opts[:after] && opts[:after] == head_token

        open_log_file(opts) { |io| yield io }
      end

      def open_log_file(opts = {})
        cmd = "#{rev_list_command(opts)} -v > #{log_filename}"
        run cmd
        File.open(log_filename, 'r') { |io| yield io }
      ensure
        File.delete(log_filename) if File.exist?(log_filename)
      end

      # Ohloh tracks only files, not directories. This function removes directories
      # from the commit diffs.
      def remove_directories(commit)
        commit.diffs.delete_if { |d| d.path[-1..-1] == '/' }
        commit
      end

      def cat(revision, path)
        bzr_client.cat_file(revision, path)
      end

      # Bzr doesn't like it when the filename includes a colon
      # Also, fix the case where the filename includes a single quote
      def escape(path)
        path.gsub(/[:]/) { |c| '\\' + c }.gsub("'", "''")
      end

      def tag_strings
        run("cd '#{url}' && bzr tags").split(/\n/)
      end

      def time_string(rev)
        run("cd '#{url}' && bzr log -r #{rev} | grep 'timestamp:' | sed 's/timestamp://'")
      end

      def bzr_client
        @bzr_client ||= setup_bzr_client
      end

      def setup_bzr_client
        bzr_client = PyBridge::BzrClient.new(url)
        bzr_client.start
        bzr_client
      end
    end
  end
end
