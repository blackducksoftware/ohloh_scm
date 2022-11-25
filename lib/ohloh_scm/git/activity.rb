# frozen_string_literal: true

require 'ohloh_scm/data/git_ignore_list'
module OhlohScm
  module Git
    class Activity < OhlohScm::Activity
      NULL_SHA1 = '0000000000000000000000000000000000000000'

      def tags
        return [] if no_tags?

        flags = "--format='%(creatordate:iso-strict) %(objectname) %(refname)'"
        tag_strings = run("cd #{url} && git tag #{flags} | sed 's/refs\\/tags\\///'").split(/\n/)
        tag_strings.map do |tag_string|
          timestamp_string, commit_hash, tag_name = tag_string.split(/\s/)
          [tag_name, dereferenced_sha(tag_name) || commit_hash, time_object(timestamp_string)]
        end
      end

      def export(dest_dir, commit_id = 'HEAD')
        run "cd #{url} && git archive #{commit_id} | tar -C #{dest_dir} -x"
      end

      # Returns the number of commits in the repository following the commit with SHA1 'after'.
      def commit_count(opts = {})
        run("#{rev_list_command(opts)} | wc -l").to_i
      end

      def commit_tokens(opts = {})
        run(rev_list_command(opts)).split("\n")
      end

      # Yields each commit following the commit with SHA1 'after'.
      # Officially, this method isn't required to provide diffs with these commits,
      # and the Subversion equivalent of this method does not,
      # so if you really require the diffs you should be using each_commit() instead.
      def commits(opts = {})
        result = []
        each_commit(opts) { |c| result << c }
        result
      end

      # Yields each commit in the repository following the commit with SHA1 'after'.
      # These commits are populated with diffs.
      def each_commit(opts = {})
        # Bug fix (hack) follows.
        #
        # git-whatchanged emits a merge commit multiple times, once for each parent, giving the
        # delta to each parent in turn.
        #
        # This causes us to emit too many commits, with repeated merge commits.
        #
        # To fix this, we track the previous commit, and emit a new commit only if it is distinct
        # from the previous.
        #
        # This means that the diffs for a merge commit yielded by this method will be the diffs
        # vs. the first parent only, and diffs vs. other parents are lost.
        # For OpenHub, this is fine because OpenHub ignores merge diffs anyway.
        previous = nil
        safe_open_log_file(opts) do |io|
          OhlohScm::GitParser.parse(io) do |e|
            yield fixup_null_merge(e) unless previous && previous.token == e.token
            previous = e
          end
        end
      end

      # Returns a single commit, including its diffs
      def verbose_commit(token)
        cmd = "cd '#{url}' && #{OhlohScm::GitParser.whatchanged} #{token}"\
              " | #{string_encoder_path}"
        commit = OhlohScm::GitParser.parse(run(cmd)).first
        fixup_null_merge(commit)
      end

      # For a merge commit, we ask `git whatchanged` to output the changes relative to each parent.
      # It is possible, through dev hacks, to create a merge commit which does not change the tree.
      # When this happens, `git whatchanged` will suppress its output relative to the first parent,
      # and jump immediately to the second (branch) parent. Our code mistakenly interprets this
      # output as the missing changes relative to the first parent.
      #
      # To avoid this calamity, we compare the tree hash of this commit with its first parent's.
      # If they are equal, then the diff must be empty, regardless of what `git whatchanged` says.
      #
      # Yes, this is a convoluted, time-wasting hack to address a very rare circumstance.
      # Ultimately we should stop parsing `git whatchanged` to extract commit data.
      def fixup_null_merge(commit)
        first_parent_token = parent_tokens(commit).first
        if first_parent_token &&
           get_commit_tree(first_parent_token) == get_commit_tree(commit.token)
          commit.diffs = []
        end
        commit
      end

      def head_token
        run("git ls-remote --heads '#{url}' #{scm.branch_name}") =~ /^(^[a-z0-9]{40})\s+\S+$/
        Regexp.last_match(1)
      end

      def head
        verbose_commit(head_token)
      end

      def cat_file(_commit, diff)
        cat(diff.sha1)
      end

      def cat_file_parent(_commit, diff)
        cat(diff.parent_sha1)
      end

      def branches
        cmd = "cd '#{url}' && git branch | #{string_encoder_path}"
        run(cmd).split.select { |branch_name| branch_name =~ /\b(.+)$/ }
      end

      # Commit all changes in the working directory, using metadata from the passed commit.
      def commit_all(commit = Commit.new)
        init_db
        ensure_gitignore
        write_token(commit.token)

        # Establish the author, email, message, etc. for the git-commit.
        message_filename = build_commit_metadata(commit)

        run "cd '#{url}' && git add ."
        if anything_to_commit?
          run "cd '#{url}' && git commit -a -F #{message_filename}"
        else
          logger.info { 'nothing to commit' }
        end
      end

      # Determine the most recent revision that was safely stored in the GIT archive.
      # Resets the token file on disk to the most recent version stored in the repository.
      def read_token
        return nil unless status.exist?

        begin
          cmd = "git cat-file -p `git ls-tree HEAD #{token_filename} | cut -c 13-51`"
          token = run("cd '#{url}' && #{cmd}").strip
        rescue RuntimeError => e
          # If the git repository doesn't have a token file yet, it will error out.
          # We want to just quietly return nil.
          return nil if /pathspec '#{token_filename}' did not match any file\(s\) known to git/
                        .match?(e.message)

          raise
        end
        token
      end

      private

      def cat(sha1)
        return '' if sha1 == NULL_SHA1

        run "cd '#{url}' && git cat-file -p #{sha1}"
      end

      def parent_tokens(commit)
        run("cd '#{url}' && git cat-file commit #{commit.token} | grep ^parent | cut -f 2 -d ' '")
          .split("\n")
      end

      # For a given commit ID, returns the SHA1 hash of its tree
      def get_commit_tree(token = 'HEAD')
        run("cd #{url} && git cat-file commit #{token} | grep '^tree' | cut -d ' ' -f 2").strip
      end

      def safe_open_log_file(opts = {})
        return '' unless status.branch?
        return '' if opts[:after] && opts[:after] == head_token

        open_log_file(opts) { |io| yield io }
      end

      def open_log_file(opts)
        run "#{rev_list_command(opts)} | xargs -n 1 #{OhlohScm::GitParser.whatchanged}"\
              " | #{string_encoder_path} > #{log_filename}"
        File.open(log_filename, 'r') { |io| yield io }
      ensure
        File.delete(log_filename) if File.exist?(log_filename)
      end

      def rev_list_command(opts = {})
        up_to = opts[:up_to] || "heads/#{scm.branch_name}"
        range = opts[:after] ? "#{opts[:after]}..#{up_to}" : up_to

        trunk_only = opts[:trunk_only] ? '--first-parent' : ''
        "cd '#{url}' && git rev-list --topo-order --reverse #{trunk_only} #{range}"
      end

      def dereferenced_sha(tag_name)
        dtag_sha_and_name = dtag_sha_and_names.find do |sha_and_name|
          sha_and_name.last == tag_name
        end
        dtag_sha_and_name&.first
      end

      def dtag_sha_and_names
        @dtag_sha_and_names ||= dereferenced_tag_strings.map(&:split)
      end

      def dereferenced_tag_strings
        # Pattern: b6e9220c3cabe53a4ed7f32952aeaeb8a822603d refs/tags/v1.0.0^{}
        run("cd #{url} && git show-ref --tags -d | grep '\\^{}' | sed 's/\\^{}//'"\
              " | sed 's/refs\\/tags\\///'").split(/\n/)
      end

      def time_object(timestamp_string)
        timestamp_string = '1970-01-01' if timestamp_string.strip.empty?
        Time.parse(timestamp_string)
      end

      def no_tags?
        run("cd #{url} && git tag | head -1").empty?
      end

      # Store all of the commit metadata in the GIT environment variables
      # where they will be picked up by the git-commit command.
      #
      # Commit info is required.
      # Author info is optional, and defaults to committer info.
      def build_commit_metadata(commit)
        configure_git_environment_variables(commit)
        # This is a one-off fix for DrJava, which includes some escape characters
        # in one of its Subversion messages. This might lead to a more generalized
        # cleanup of message text, but for now...
        commit.message = commit.message&.gsub(/\\027/, '')

        # Git requires a non-empty message
        commit.message = '[no message]' if commit.message.nil? || commit.message =~ /\A\s*\z/

        # We need to store the message in a file in case it contains crazy characters
        #    that would corrupt a bash command line.
        File.open(message_filename, 'w') do |f|
          f.write commit.message
        end
        message_filename
      end

      def configure_git_environment_variables(commit)
        ENV['GIT_COMMITTER_NAME'] = commit.committer_name || '[anonymous]'
        ENV['GIT_AUTHOR_NAME'] = commit.author_name || ENV['GIT_COMMITTER_NAME']

        ENV['GIT_COMMITTER_EMAIL'] = commit.committer_email || ENV['GIT_COMMITTER_NAME']
        ENV['GIT_AUTHOR_EMAIL'] = commit.author_email || ENV['GIT_AUTHOR_NAME']

        ENV['GIT_COMMITTER_DATE'] = commit.committer_date.to_s
        ENV['GIT_AUTHOR_DATE'] = (commit.author_date || commit.committer_date).to_s
      end

      # By hiding the message file inside the .git directory, we
      #    avoid it being found by the commit-all.
      def message_filename
        File.expand_path(File.join(scm.vcs_path, 'ohloh_message'))
      end

      # True if there are pending changes to commit.
      def anything_to_commit?
        /nothing to commit/.match?(run("cd '#{url}' && git status | tail -1")) ? false : true
      end

      # Ensures that the repository directory exists, and that the git db has been initialized.
      def init_db
        run "mkdir -p '#{url}'" unless FileTest.exist? url
        run "cd '#{url}' && git init-db" unless status.scm_dir_exist?
      end

      # The .gitignore file will be created if it does not exist.
      # If our desired filespec is not found in .gitignore, it will be appended
      # to the end of .gitignore.
      def ensure_gitignore
        GIT_IGNORE_LIST.each do |ignore|
          gitignore_filename = File.join(url, '.gitignore')
          found = check_if_ignored(gitignore_filename, ignore)
          next if found

          File.open(gitignore_filename, File::APPEND | File::WRONLY) do |io|
            io.puts ignore
          end
        end
      end

      def check_if_ignored(gitignore_filename, filespec)
        File.open(gitignore_filename, File::CREAT | File::RDONLY) do |io|
          io.readlines.each do |l|
            return true && break if l.chomp == filespec
          end
        end
      end

      def token_filename
        'ohloh_token'
      end

      def token_path
        File.join(url, token_filename)
      end

      # Saves the new token in a well-known file.
      # If the passed token is empty, this method silently does nothing.
      def write_token(token)
        return unless token && !token.to_s.empty?

        File.open(token_path, 'w') do |f|
          f.write token.to_s
        end
      end
    end
  end
end
