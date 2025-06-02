# frozen_string_literal: true

module OhlohScm
  # This parser processes Mercurial logs which have been generated using a custom style.
  # This custom style provides additional information required by Ohloh.
  class HgParser < Parser
    class << self
      # Use when you want to include diffs
      def verbose_style_path
        File.expand_path("#{__dir__}/hg_verbose_style")
      end

      # Use when you do not want to include diffs
      def style_path
        File.expand_path("#{__dir__}/hg_style")
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def internal_parse(buffer, _)
        e = nil
        state = :data

        buffer.each_line do |line|
          next_state = state
          case state
          when :data
            case line
            when /^changeset:\s+([0-9a-f]+)/
              e = build_commit(Regexp.last_match(1))
            when /^user:\s+(.+?)(\s+<(.+)>)?$/
              e.committer_name = Regexp.last_match(1)
              e.committer_email = Regexp.last_match(3)
            when /^date:\s+([\d.]+)/
              time = Regexp.last_match(1)
              e.committer_date = Time.at(time.to_f).utc
            when "__BEGIN_FILES__\n"
              next_state = :files
            when "__BEGIN_COMMENT__\n"
              next_state = :long_comment
            when "__END_COMMIT__\n"
              yield e if block_given?
              e = nil
            end

          when :files
            case line
            when "__END_FILES__\n"
              next_state = :data
            when /^([MAD]) (.+)$/
              e.diffs << OhlohScm::Diff.new(action: Regexp.last_match(1),
                                            path: Regexp.last_match(2))
            end

          when :long_comment
            if line == "__END_COMMENT__\n"
              next_state = :data
            elsif e.message
              e.message << line
            else
              e.message = line
            end
          end
          state = next_state
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      def build_commit(token)
        OhlohScm::Commit.new.tap do |commit|
          commit.diffs = []
          commit.token = token
        end
      end
    end
  end
end
