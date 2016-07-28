module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def head_token
      info =~ /^Revision: (\d+)$/ ? $1.to_i : nil
    end

    private

    def info
      return unless File.exist?("#{ url }/.git")
      run_in_url "git svn info"
    end
  end
end
