# frozen_string_literal: true

module OhlohScm
  # This parser processes Git whatchanged generated using a custom style.
  # This custom style provides additional information required by OpenHub.
  class GitParser < Parser
    class << self
      def whatchanged
        "git whatchanged --root -m --abbrev=40 --max-count=1 --always --pretty=#{format}"
      end

      def format
        "format:'__BEGIN_COMMIT__%nCommit: %H%nAuthor: %an%nAuthorEmail:"\
          " %ae%nDate: %aD%n__BEGIN_COMMENT__%n%s%n%b%n__END_COMMENT__%n'"
      end

      ANONYMOUS = '(no author)' unless defined?(ANONYMOUS)

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def internal_parse(io, _)
        e = nil
        state = :key_values
        io.each do |line|
          line.chomp!

          # Kind of a hack: the diffs section is not always present.
          # If we are expecting a line of diffs, but instead find a line
          # starting with "Commit: ", that means the diffs section
          # is missing for this commit,  and we need to fix up our state.
          state = :key_values if state == :diffs && line =~ /^Commit: ([a-z0-9]+)$/

          if state == :key_values
            if line =~ /^Commit: ([a-z0-9]+)$/
              sha1 = Regexp.last_match(1)
              yield e if e
              e = build_commit(sha1)
            elsif line =~ /^Author: (.+)$/
              e.author_name = Regexp.last_match(1)
            elsif line =~ /^Date: (.*)$/
              # MUST be RFC2822 format to parse properly, else defaults to epoch time
              e.author_date = parse_date(Regexp.last_match(1))
            elsif line == '__BEGIN_COMMENT__'
              state = :message
            elsif line =~ /^AuthorEmail: (.+)$/
              e.author_email = Regexp.last_match(1)
              # In the rare case that the Git repository does not contain any names,
              #   we use the email instead (see OpenEmbedded for example).
              if e.author_name.to_s.empty? || e.author_name == ANONYMOUS
                e.author_name = Regexp.last_match(1)
              end
            end

          elsif state == :message
            if line == '__END_COMMENT__'
              state = :diffs
            elsif line != '<unknown>'
              if e.message
                e.message << "\n" << line
              else
                e.message = line
              end
            end

          elsif state == :diffs
            if line == '__BEGIN_COMMIT__'
              state = :key_values
            # Ref: https://git-scm.com/docs/git-diff-index#Documentation/git-diff-index.txt-git-diff-filesltpatterngt82308203
            elsif line =~ /:([0-9]+) ([0-9]+) ([a-z0-9]+) ([a-z0-9]+) ([A-Z])\t"?(.+)"?$/
              add_generic_diff(e, Regexp.last_match)
            elsif line =~ /:([0-9]+) ([0-9]+) ([a-z0-9]+) ([a-z0-9]+) (R[0-9]+)\t"?(.+)"?$/
              add_rename_edit_diff(e, Regexp.last_match)
            end
          else
            raise RuntimeError("Unknown parser state #{state}")
          end
        end

        yield e if e
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/BlockLength
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      def build_commit(sha1)
        commit = OhlohScm::Commit.new
        commit.diffs = []
        commit.token = sha1
        commit.author_name = ANONYMOUS
        commit
      end

      def add_generic_diff(commit, match_data)
        src_mode, dst_mode, parent_sha1, sha1, action, path = match_data[1..-1]

        return if path == '.gitmodules' # contains submodule path config.
        # Submodules have a file mode of '160000'(gitlink). We ignore submodules completely.
        return if src_mode == '160000' || dst_mode == '160000'

        commit.diffs << OhlohScm::Diff.new(action: action, path: path,
                                           sha1: sha1, parent_sha1: parent_sha1)
      end

      def add_rename_edit_diff(commit, match_data)
        src_mode, dst_mode, parent_sha1, sha1, _, path = match_data[1..-1]

        return if src_mode == '160000' || dst_mode == '160000'

        old_path, new_path = path.split("\t")
        commit.diffs << OhlohScm::Diff.new(action: 'D', path: old_path,
                                           sha1: null_sha1, parent_sha1: parent_sha1)
        commit.diffs << OhlohScm::Diff.new(action: 'A', path: new_path,
                                           sha1: sha1, parent_sha1: null_sha1)
      end

      def null_sha1
        OhlohScm::Git::Activity::NULL_SHA1
      end

      def parse_date(date)
        Time.rfc2822(date).utc
      rescue ArgumentError
        Time.at(0)
      end
    end
  end
end
