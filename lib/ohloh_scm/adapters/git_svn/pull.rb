module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def pull(source_scm, &block)
      @source_scm = source_scm
      convert_to_git(&block)
    end

    def branch_name
      'master'
    end

    private

    def convert_to_git(&block)
      yield(0, 1) if block_given?

      if FileTest.exist?(git_path)
        accept_certificate_if_prompted
        fetch(&block)
      else
        clone(&block)
      end

      clean_up_disk
    end

    def clone(&block)
      prepare_dest_dir
      accept_certificate_if_prompted

      max_step = commit_count(after: 0)
      cmd = "#{password_prompt} git svn clone --quiet #{username_opts} '#{@source_scm.url}' '#{self.url}'"
      track_conversion(cmd, max_step, &block)
    end

    def track_conversion(cmd, max_step)
      count = 0
      IO.popen(cmd).each do |line|
        yield(count += 1, max_step) if line.match(/^r\d+/) && block_given?
      end
      yield(max_step, max_step) if block_given?
    end

    def accept_certificate_if_prompted
      # git svn does not support non iteractive and serv-certificate options
      # Permanently accept svn certificate when it prompts
      opts = "#{username_opts} #{password_opts}"
      opts = '--xml' if opts.strip.empty?
      run "#{accept_ssl_certificate_cmd} '#{opts}' '#{@source_scm.url}'"
    end

    def accept_ssl_certificate_cmd
      File.expand_path('../../../../../bin/accept_svn_ssl_certificate', __FILE__)
    end

    def password_prompt
      @source_scm.password.to_s.empty? ? '' : "echo #{ @source_scm.password } |"
    end

    def password_opts
      @source_scm.password.to_s.empty? ? '' : "--password='#{@source_scm.password}'"
    end

    def username_opts
      @source_scm.username.to_s.empty? ? '' : "--username #{ @source_scm.username }"
    end

    def prepare_dest_dir
      FileUtils.mkdir_p(self.url)
      FileUtils.rmdir(self.url)
    end

    def fetch(&block)
      max_step = commit_count(after: head_token)
      cmd = "cd #{self.url} && git svn fetch"
      track_conversion(cmd, max_step, &block)
    end

    def git_path
      File.join(self.url, '/.git')
    end

    def clean_up_disk
      if FileTest.exist?(self.url)
        run("cd #{self.url} && find . -maxdepth 1 -not -name .git -not -name . -print0 | xargs -0 rm -rf --")
      end
    end
  end
end
