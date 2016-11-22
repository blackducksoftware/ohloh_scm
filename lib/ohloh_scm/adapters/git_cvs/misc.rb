module OhlohScm::Adapters
  class GitCvsAdapter < GitAdapter
    private

    def run_in_url(command)
      run "cd #{ url } && #{ command }"
    end
  end
end
