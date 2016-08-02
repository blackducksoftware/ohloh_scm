module OhlohScm::Adapters
  class GitCvsAdapter < GitAdapter
    def pull(source_scm)
      clone_or_fetch(source_scm)
    end

    private

    def clone_or_fetch(source_scm)
      system "mkdir -p #{ url }" unless exist?

      module_tag = source_scm.module_name || source_scm.branch_name
      run_in_url "git cvsimport -aR -d #{ source_scm.url } #{ module_tag }"

      clean_up_disk
    end
  end
end
