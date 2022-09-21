# frozen_string_literal: true

module OhlohScm
  module Git
    class Scm < OhlohScm::Scm
      def initialize(core:, url:, branch_name:, username:, password:)
        super
        @branch_name = branch_name || 'master'
      end

      # == Example:
      #   remote_core = OhlohScm::Factory.get_core(url: 'https://github.com/ruby/ruby')
      #   local_core = OhlohScm::Factory.get_core(url: '/tmp/ruby-src')
      #   local_core.scm.pull(remote_core.scm)
      def pull(from, callback)
        case from
        when Cvs::Scm then convert_to_git(from, callback)
        else clone_or_fetch(from, callback)
        end
      end

      def vcs_path
        "#{url}/.git"
      end

      def checkout_files(names)
        filenames = names.map { |name| "*#{name}" }.join(' ')
        run "cd #{url} && git checkout $(git ls-files #{filenames})"
      end

      private

      def clone_or_fetch(remote_scm, callback)
        callback.update(0, 1)
        if status.exist? && status.branch?(branch_name)
          clean_and_checkout_branch # must be on correct branch, but we want to be careful.
          fetch_new_commits(remote_scm)
        else
          clone_and_create_tracking_branch(remote_scm)
        end
        clean_up_disk
        callback.update(1, 1)
      end

      def fetch_new_commits(remote_scm)
        run "cd '#{url}' && git fetch --tags --update-head-ok "\
              "'#{remote_scm.url}' #{branch_name}:#{branch_name}"
      end

      def clone_and_create_tracking_branch(remote_scm)
        unless status.scm_dir_exist? || status.exist?
          run "rm -rf '#{url}'"
          run "git clone -q -n '#{remote_scm.url}' '#{url}'"
        end
        create_tracking_branch(remote_scm.branch_name) # ensure the correct branch exists locally
        clean_and_checkout_branch # switch to the correct branch
      end

      # We need very high reliability and this sequence gets the job done every time.
      def clean_and_checkout_branch
        return unless status.scm_dir_exist?

        run "cd '#{url}' && git clean -f -d -x --exclude='*.nfs*'"
        return unless status.branch?(branch_name)

        run "cd '#{url}' && git checkout #{branch_name} --"
        run "cd '#{url}' && git reset --hard heads/#{branch_name} --"
      end

      def create_tracking_branch(branch_name)
        return if branch_name.to_s.empty?
        return if activity.branches.include?(branch_name)

        run "cd '#{url}' && git remote update && git branch -f #{branch_name} origin/#{branch_name}"
      end

      # Deletes everything but the *.git* folder in the working directory.
      def clean_up_disk
        return unless Dir.exist?(url)

        run "cd #{url} && find . -maxdepth 1 -not -name .git -not -name '*.nfs*' -not -name . -print0"\
              ' | xargs -0 rm -rf --'
      end

      def convert_to_git(remote_scm, callback)
        callback.update(0, 1)

        commits = remote_scm.activity.commits(after: activity.read_token)
        check_empty_repository(commits)

        if commits && !commits.empty?
          setup_dir_and_convert_commits(commits, callback)
        else
          logger.info { 'Already up-to-date.' }
        end
      end

      def setup_dir_and_convert_commits(commits, callback)
        set_up_working_directory
        convert(commits, callback)
        callback.update(commits.size, commits.size)
      end

      def convert(commits, callback)
        commits.each_with_index do |r, i|
          callback.update(i, commits.size)
          create_git_commit(r, i, commits.size)
        end
      end

      def check_empty_repository(commits)
        raise 'Empty repository' if !activity.read_token && commits.empty?
      end

      def set_up_working_directory
        # Start by making sure we are in a known good state. Set up our working directory.
        clean_up_disk
        clean_and_checkout_branch
      end

      def handle_checkout_error(commit)
        logger.error { $ERROR_INFO.inspect }
        # If we fail to checkout, it's often because there is junk of some kind
        # in our working directory.
        logger.info { 'Checkout failed. Cleaning and trying again...' }
        clean_up_disk
        commit.scm.checkout(commit, url)
      end

      def create_git_commit(commit, index, size)
        logger.info { "Downloading revision #{commit.token} (#{index + 1} of #{size})... " }
        checkout(commit)
        logger.debug { "Committing revision #{commit.token} (#{index + 1} of #{size})... " }
        activity.commit_all(commit)
      end

      def checkout(commit)
        commit.scm.checkout(commit, url)
      rescue StandardError
        handle_checkout_error(commit)
      end
    end
  end
end
