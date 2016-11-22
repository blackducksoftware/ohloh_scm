module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def pull(source_scm, &block)
      @source_scm = source_scm
      clone_or_fetch(&block)
    end

    private

    def clone_or_fetch(&block)
      if exist?
        commit_count = @source_scm.commit_count(after: head_token)
        command = "cd #{ url } && git svn fetch"
        track_converted_commits(command, commit_count, &block)
      else
        run "rm -rf #{ url }"
        clone(&block)
      end

      clean_up_disk
    end

    def clone(&block)
      commit_count = @source_scm.commit_count
      branch_tag = "--trunk #{ @source_scm.branch_name }" if @source_scm.branch_name
      command = "#{ password_opts } git svn clone -q #{ username_opts } #{ @source_scm.root } #{ branch_tag } #{ url }"
      track_converted_commits(command, commit_count, &block)
    end

    def track_converted_commits(command, total_count)
      count = 0

      IO.popen(command).each do |line|
        yield(count += 1, total_count) if line.match(/^r\d+/) && block_given?
      end
    end

    def password_opts
      "echo #{ @source_scm.password } |" unless @source_scm.username.to_s.empty?
    end

    def username_opts
      "--username #{ @source_scm.username }" unless @source_scm.username.to_s.empty?
    end

    def clean_up_disk
      if FileTest.exist? url
        run_in_url 'find . -maxdepth 1 -not -name .git -not -name . -print0 | xargs -0 rm -rf --'
      end
    end
  end
end
