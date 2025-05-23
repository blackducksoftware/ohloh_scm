# frozen_string_literal: true

module OhlohScm
  module Cvs
    class Activity < OhlohScm::Activity
      def tags
        cmd = "cvs -Q -d #{url} rlog -h #{scm.branch_name} | awk -F\"[.:]\" '/^\\t/&&$(NF-1)!=0'"
        run(cmd).split(/\n/).map do |tag_string|
          tag_name, version = tag_string.split(':')
          [tag_name.delete("\t"), version.strip]
        end
      end

      def commits(opts = {})
        result = fetch_commits(opts)
        return result if result.empty? || opts[:after].to_s.empty?

        filter_commits(result, opts[:after])
      end

      private

      def fetch_commits(opts)
        OhlohScm::CvsParser.parse(open_log_file(opts)).tap do |result|
          result.each { |c| c.scm = scm }
        end
      end

      def filter_commits(commits, after)
        return commits if first_commit_newer?(commits, after)

        timestamp_regex = create_timestamp_regex(after)
        match_index = find_match_index(commits, timestamp_regex)

        extract_new_commits(commits, match_index)
      end

      def first_commit_newer?(commits, after)
        parse_time(commits.first.token) > parse_time(after)
      end

      def create_timestamp_regex(timestamp)
        Regexp.new(timestamp.gsub(/[\/-]/, '.'))
      end

      def find_match_index(commits, timestamp_regex)
        commits.index { |commit| commit.token&.match?(timestamp_regex) }
      end

      def extract_new_commits(commits, match_index)
        case match_index
        when nil
          raise 'token not found in rlog.'
        when commits.size - 1
          []
        else
          commits[match_index + 1..-1]
        end
      end

      # Other methods remain the same...
    end
  end
end
