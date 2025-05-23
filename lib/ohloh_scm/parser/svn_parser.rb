# frozen_string_literal: true

module OhlohScm
  class SvnParser < Parser
    class << self
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def internal_parse(buffer, _opts)
        e = nil
        state = :data
        previous_state = nil
        previous_line = nil

        buffer.each_line do |l|
          l.chomp!
          next_state = state
          if state == :data
            if l =~ /^r(\d+) \| (.*) \| (\d+-\d+-\d+ .*) \(.*\) \| .*/
              yield e if e && block_given?

              e = OhlohScm::Commit.new
              e.token = Regexp.last_match(1).to_i
              e.committer_name = Regexp.last_match(2)
              e.committer_date = Time.parse(Regexp.last_match(3)).utc
            elsif l == 'Changed paths:'
              next_state = :diffs
            elsif l.empty?
              next_state = :comment
            elsif previous_state == :comment
              next_state = :comment
              e.message ||= ''
              e.message << "\n"
              e.message << previous_line
              e.message << "\n"
              e.message << l
            end

          elsif state == :diffs
            if l =~ /^   (\w) ([^\(\)]+)( \(from (.+):(\d+)\))?$/
              e.diffs ||= []
              e.diffs << OhlohScm::Diff.new(action: Regexp.last_match(1),
                                            path: Regexp.last_match(2),
                                            from_path: Regexp.last_match(4),
                                            from_revision: Regexp.last_match(5).to_i)
            else
              next_state = :comment
            end

          # The :log_embedded_within_comment state is special-case code to fix the Wireshark
          # project, which includes fragments of svn logs within its comment blocks, which really
          # confuses the parser. I am not sure whether only Wireshark does this, but I suspect it
          # happens because there is a tool out there somewhere to generate
          # these embedded log comments.
          elsif state == :log_embedded_within_comment
            e.message << "\n"
            e.message << l
            next_state = :comment if /============================ .* log end =+/.match?(l)

          elsif state == :comment
            if /------------------------------------------------------------------------/.match?(l)
              next_state = :data
            elsif /============================ .* log start =+/.match?(l)
              e.message << "\n"
              e.message << l
              next_state = :log_embedded_within_comment
            elsif e.message
              e.message << "\n"
              e.message << l
            else
              e.message = l
            end
          end
          previous_state = state
          state = next_state
          previous_line = l
        end
        yield e if block_given?
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    end
  end
end
