module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def pull(source_scm)
      clone_or_fetch(source_scm)
    end

    private

    def clone_or_fetch(source_scm)
      if self.exist?
        run_in_url 'git svn fetch'
      else
        system "git svn clone -qq --stdlayout #{ source_scm.root } #{ url_without_file_protocol }"
      end

      clean_up_disk
    end

    def clean_up_disk
      if FileTest.exist? url
        run_in_url 'find . -maxdepth 1 -not -name .git -not -name . -print0 | xargs -0 rm -rf --'
      end
    end
  end
end
