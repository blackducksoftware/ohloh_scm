# frozen_string_literal: true

module OhlohScm
  class CvsParser < Parser
    class << self
      # Given an IO to a CVS rlog, returns a list of
      # commits (developer/date/message).
      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def internal_parse(io, _opts)
        commits = {}

        read_files(io) do |c|
          # As commits are yielded by the parser, we sort them into bins.
          #
          # The 'bins' are arrays of timestamps. We keep a separate array of
          # timestamps for each developer/message combination.
          #
          # If a commit lies near in time to another commit with the same
          # developer/message combination, then we merge them and store only
          # the later of the two timestamps.
          #
          # Typically, we end up with only a single timestamp for each developer/message
          # combination. However, if a developer repeatedly uses the same message
          # a number of separate times, we may end up with several timestamps for
          # that combination.

          key = c.committer_name + ':' + c.message
          if commits.key? key
            # We have already seen this developer/message combination
            match = false
            commits[key].each_index do |i|
              # Does the new commit lie near in time to a known one in our list?
              next unless near?(commits[key][i].committer_date, c.committer_date)

              match = true
              # Yes. Choose the most recent timestamp, and add the new
              # directory name to our list.
              if commits[key][i].committer_date < c.committer_date
                commits[key][i].committer_date = c.committer_date
                commits[key][i].token = c.token
              end
              unless commits[key][i].directories.include? c.directories[0]
                commits[key][i].directories << c.directories[0]
              end
              break
            end
            # This commit lies a long time away from any one we know.
            # Add it to the list as a new checkin event.
            commits[key] << c unless match
          else
            # We have never seen this developer/message combination. Start a new list.
            commits[key] = [c]
          end
        end
        # Pull all of the commits out of the hash and return them as a single sorted list.
        result = commits.values.flatten.sort! { |a, b| a.committer_date <=> b.committer_date }

        # If we have two commits with identical timestamps, arbitrarily choose the first
        (result.size - 1).downto(1) do |i|
          result.delete_at(i) if result[i].committer_date == result[i - 1].committer_date
        end

        result.each { |r| yield r } if block_given?
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      # Accepts two dates and
      # determines wether they are close enough together to consider simultaneous.
      def near?(date1, date2)
        ((date1 - date2).abs < 30 * 60) # Less than 30 minutes counts as 'near'
      end

      def read_files(io, &block)
        io.each_line do |l|
          if l =~ /^RCS file: (.*),.$/
            filename = Regexp.last_match(1)
            read_file(io, filename, &block)
          end
        end
      end

      def read_file(io, filename, &block)
        branch_number = nil
        io.each_line do |l|
          if l =~ /^head: ([\d\.]+)/
            branch_number = BranchNumber.new(Regexp.last_match(1))
          elsif /^----------------------------/.match?(l)
            read_commits(io, branch_number, filename, &block)
          end
        end
      end

      def read_commits(io, branch_number, filename, &block)
        should_yield = nil
        io.each_line do |l|
          break if /^\s$/.match?(l)

          l =~ /^revision ([\d.]+)/
          commit_number = Regexp.last_match(1)
          should_yield = branch_number&.on_same_line?(BranchNumber.new(commit_number))
          read_commit(io, filename, commit_number, should_yield, &block)
        end
      end

      def read_commit(io, filename, commit_number, should_yield)
        io.each_line do |l|
          next unless l =~ /^date: (.*);  author: ([^;]+);  state: (\w+);/

          state = Regexp.last_match(3)
          # CVS creates a "phantom" dead file at 1.1 on the head if a file
          #   is created on a branch. Ignore this file.
          should_yield = false if (commit_number == '1.1') && (state == 'dead')
          message = read_message(io)
          if should_yield
            yield build_commit(Regexp.last_match(1), Regexp.last_match(2), message, filename)
          end
          break
        end
      end

      def build_commit(committer_date, committer_name, message, filename)
        commit = OhlohScm::Commit.new
        commit.token = committer_date[0..18]
        commit.committer_date = Time.parse(committer_date[0..18] + ' +0000').utc
        commit.committer_name = committer_name
        commit.message = message
        commit.directories = [File.dirname(filename).intern]
        commit
      end

      # rubocop:disable Metrics/MethodLength
      def read_message(io)
        message = ''
        first_line = true
        io.each_line do |l|
          unless l =~ /^branches: / && first_line # the first line might be 'branches:', skip it.
            l.chomp!
            return message if separator?(l)

            message += "\n" unless message.empty?
            message += l
          end
          first_line = false
        end
        message
      end
      # rubocop:enable Metrics/MethodLength

      def separator?(line)
        %w[=============================================================================
           ----------------------------].include?(line)
      end
    end
  end
end
