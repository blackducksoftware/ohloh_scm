# frozen_string_literal: true

require 'shellwords'
module OhlohScm
  module Hg
    class Activity < OhlohScm::Activity
      def commit_count(opts = {})
        commit_tokens(opts).size
      end

      def commit_tokens(opts = {})
        hg_log_with_opts, after = hg_log_cmd_builder(opts)
        # We reverse the final result in Ruby, rather than passing the --reverse flag to hg.
        # That's because the -f (follow) flag doesn't behave the same in both directions.
        # Basically, we're trying very hard to make this act just like Git.
        tokens = run("cd '#{url}' && #{hg_log_with_opts} --template='{node}\\n'")
                 .split("\n").reverse

        # Since hg v4, --follow-first does not play well with -r N:n,
        #   using them together always returns all commits.
        # To find trunk commits since a given revision,
        #   we get all trunk commits and drop older commits before given revision.
        tokens = tokens.drop(tokens.index(after)) if tokens.any? && after && after != 0

        # This includes everything after *and including* after.
        tokens.shift if tokens.first == after
        tokens
      end

      # Returns a list of shallow commits (i.e., the diffs are not populated).
      def commits(opts = {})
        hg_log_with_opts, after = hg_log_cmd_builder(opts)

        log = run("cd '#{url}' && #{hg_log_with_opts} --style #{OhlohScm::HgParser.style_path}")

        commit_objects = OhlohScm::HgParser.parse(log).reverse
        commit_objects.shift if commit_objects.first&.token == after
        commit_objects
      end

      # Returns a single commit, including its diffs
      def verbose_commit(token)
        cmd = "cd '#{url}' && hg log -v -r #{token} "\
              " --style #{OhlohScm::HgParser.verbose_style_path} | #{string_encoder_path}"
        OhlohScm::HgParser.parse(run(cmd)).first
      end

      # Yields each commit after +after+, including its diffs.
      # The log is stored in a temporary file.
      # This is designed to prevent excessive RAM usage when we encounter a massive repository.
      # Only a single commit is ever held in memory at once.
      def each_commit(opts = {})
        after = opts[:after] || 0
        open_log_file(opts) do |io|
          commits = OhlohScm::HgParser.parse(io)
          # NOTE: commits.reverse.each & commits.reverse_each produce different ordered sequences.
          # rubocop:disable Performance/ReverseEach
          commits.reverse.each do |commit|
            yield commit if block_given? && commit.token != after
          end
          # rubocop:enable Performance/ReverseEach
        end
      end

      def export(dest_dir, token = 'tip')
        run("cd '#{url}' && hg archive -r #{token} '#{dest_dir}'")

        # Hg leaves a little cookie crumb in the export directory. Remove it.
        file_path = File.join(dest_dir, '.hg_archival.txt')
        File.delete(file_path) if File.exist?(file_path)
      end

      def tags
        tag_strings = run("cd '#{url}' && hg tags").split(/\n/)
        tag_strings.map do |tag_string|
          parsed_str = tag_string.split(' ')
          rev_number_and_hash = parsed_str.pop
          tag_name = parsed_str.join(' ')
          rev = rev_number_and_hash.slice(/\A\d+/)
          time_string = run("cd '#{url}' && hg log -r #{rev} | grep 'date:' | sed 's/date://'")
          [tag_name, rev, Time.parse(time_string)]
        end
      end

      def cat_file(commit, diff)
        hg_client.cat_file(commit.token, diff.path)
      end

      def cat_file_parent(commit, diff)
        tokens = parent_tokens(commit)
        hg_client.cat_file(tokens.first, diff.path) if tokens.first
      end

      def head_token
        branch_opts = "--rev #{scm.branch_name_or_default}"
        # This only returns first 12 characters.
        # How can we make it return the entire hash?
        token = run("hg id --debug -i -q #{url} #{branch_opts}").strip

        # Recent versions of Hg now somtimes append a '+' char to the token.
        # Strip the trailing '+', if any.
        token = token[0..-2] if token[-1..-1] == '+'

        token
      end

      def head
        verbose_commit(head_token)
      end

      def cleanup
        hg_client.shutdown
      end

      private

      # Our standards require +opts={ after: ... }+ to include everything AFTER +after+.
      # However, hg returns everything after and INCLUDING +after+.
      # Therefore, consumers of this endpoint must check for and reject the duplicate commit.
      def open_log_file(opts = {})
        get_hg_log(opts)
        File.open(log_filename, 'r') { |io| yield io }
      ensure
        File.delete(log_filename) if File.exist?(log_filename)
      end

      def get_hg_log(opts)
        hg_log_with_opts, after = hg_log_cmd_builder(opts)
        if after == head_token # There are no new commits
          # As a time optimization,
          #  just create an empty file rather than fetch a log we know will be empty.
          File.write(log_filename, '')
        else
          cmd = "cd '#{url}' && #{hg_log_with_opts}"\
                " --style #{OhlohScm::HgParser.verbose_style_path} | #{string_encoder_path}"\
                " > #{log_filename}"
          run cmd
        end
      end

      def parent_tokens(commit)
        hg_client.parent_tokens(commit.token)
      end

      def cat(revision, path)
        out, err = run_with_err("cd '#{url}' && hg cat -r #{revision} #{escape(path)}")
        return if err =~ /No such file in rev/i
        raise err unless err&.empty?

        out
      end

      # Escape bash-significant characters in the filename
      # Example:
      #     "Foo Bar & Baz" => "Foo\ Bar\ \&\ Baz"
      def escape(path)
        Shellwords.escape(path)
      end

      def hg_log_cmd_builder(opts)
        after = opts[:after] || 0
        up_to = opts[:up_to] || :tip

        options = if opts[:trunk_only]
                    '--follow-first'
                  else
                    branch = scm.branch_name_or_default
                    "-r '#{up_to}:#{after} and (branch(#{branch}) or ancestors(#{branch}))'"
                  end

        ["hg log -v #{options}", after]
      end

      def hg_client
        @hg_client ||= setup_hg_client
      end

      def setup_hg_client
        hg_client = PyBridge::HgClient.new(url)
        hg_client.start
        hg_client
      end
    end
  end
end
