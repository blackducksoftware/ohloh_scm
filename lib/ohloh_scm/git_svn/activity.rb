# frozen_string_literal: true

module OhlohScm
  module GitSvn
    class Activity < OhlohScm::Activity
      def_delegators :scm, :url

      def commit_count(opts = {})
        cmd = "#{after_revision(opts)} | grep -E -e '^r[0-9]+.*lines$' | wc -l"
        git_svn_log(cmd: cmd, oneline: false).to_i
      end

      def commits(opts = {})
        parsed_commits = []
        open_log_file(opts) do |io|
          parsed_commits = OhlohScm::SvnParser.parse(io)
        end
        parsed_commits
      end

      def commit_tokens(opts = {})
        cmd = "#{after_revision(opts)} | #{extract_revision_number}"
        git_svn_log(cmd: cmd, oneline: false).split.map(&:to_i)
      end

      def each_commit(opts = {}, &block)
        commits(opts).each(&block)
      end

      def head_token
        cmd = "--limit=1 | #{extract_revision_number}"
        git_svn_log(cmd: cmd, oneline: false)
      end

      def cat_file(commit, diff)
        cat(git_commit(commit), diff.path)
      end

      def cat_file_parent(commit, diff)
        cat("#{git_commit(commit)}^", diff.path)
      end

      def git_commit(commit)
        run("cd #{url} && git svn find-rev r#{commit.token}").strip
      end

      private

      def open_log_file(opts = {}, &block)
        cmd = "-v #{after_revision(opts)} | #{string_encoder_path} > #{log_filename}"
        git_svn_log(cmd: cmd, oneline: false)
        File.open(log_filename, 'r', &block)
      end

      def log_filename
        File.join(temp_folder, "#{url.gsub(/\W/, '')}.log")
      end

      def after_revision(opts)
        next_token = opts[:after].to_i + 1
        next_head_token = head_token.to_i + 1
        "-r#{next_token}:#{next_head_token}"
      end

      def extract_revision_number
        "grep '^r[0-9].*|' | awk -F'|' '{print $1}' | cut -c 2-"
      end

      def git_svn_log(cmd:, oneline:)
        oneline_flag = '--oneline' if oneline
        run("#{git_svn_log_cmd} #{oneline_flag} #{cmd}").strip
      end

      def cat(revision, file_path)
        file_path = file_path.to_s
        run("cd #{url} && git show #{revision}:#{file_path.shellescape} | #{string_encoder_path}")
          .strip
      end

      def git_svn_log_cmd
        "cd #{url} && git svn log"
      end
    end
  end
end
