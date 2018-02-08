module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def pull(from, &block)
      case from
      when SvnAdapter
        convertToGit(from, &block)
      else
        logger.error { "Cannot convert #{from.english_name}/#{from.class_name} repository to git" }
      end
    end

    def branch_name
      'master'
    end

    private

    def convertToGit(source_scm)
      yield(1, 2) if block_given?

      if FileTest.exist?(git_path)
        fetch
      else
        clone(source_scm)
      end

      yield(2, 2) if block_given?
    end

    def clone(source_scm)
      # git svn does not support non iteractive and serv-certificate options
      # Permenently accept svn certificate when it prompts
      prepare_dest_dir
      run "yes p | git svn clone '#{source_scm.url}' '#{self.url}' > /dev/null 2>&1"
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
