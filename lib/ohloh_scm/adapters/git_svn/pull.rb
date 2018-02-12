module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def pull(source_scm, &block)
      @source_scm = source_scm
      convertToGit(&block)
    end

    def branch_name
      'master'
    end

    private

    def convertToGit
      yield(1, 2) if block_given?

      if FileTest.exist?(git_path)
        fetch
      else
        clone
      end

      yield(2, 2) if block_given?
    end

    def clone
      prepare_dest_dir
      accept_certificate_if_prompted
      run "#{password_prompt} git svn clone #{username_opts} '#{@source_scm.url}' '#{self.url}'"
    end

    def accept_certificate_if_prompted
      # git svn does not support non iteractive and serv-certificate options
      # Permenently accept svn certificate when it prompts
      run "echo p | svn info #{username_opts} #{password_opts} '#{ @source_scm.url }'"
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

    def fetch
      run "cd #{self.url} && git svn fetch"
      run "cd #{self.url} && git svn rebase"
    end

    def git_path
      File.join(self.url, '/.git')
    end
  end
end
