module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def commits(opts={})
      parsed_commits = []
      open_log_file(opts) do |io|
        parsed_commits = OhlohScm::Parsers::SvnParser.parse(io)
      end
      parsed_commits.reverse
    end

    def commit_tokens(opts={})
      limit = total_commit_count - opts[:after].to_i
      revs = run_in_url("git svn log --oneline --limit #{limit} #{ branch_name } | cut -f 1 -d '|' | cut -c 2-")
      revs.split.map(&:to_i).reverse
    end

    def each_commit(opts={})
      commits(opts).each do |commit|
        yield commit
      end
    end

    def commit_count(opts={})
      commit_tokens(opts).count
    end

    private

    def open_log_file(opts={})
      limit = total_commit_count - opts[:after].to_i
      run_in_url "git svn log -v --limit #{limit} #{ branch_name } | #{ string_encoder } > #{log_filename}"
      File.open(log_filename, 'r') { |io| yield io }
    end

    def total_commit_count
      run_in_url("git svn log --oneline #{ branch_name } | wc -l").to_i
    end

    def log_filename
      File.join('/tmp', url.gsub(/\W/,'') + '.log')
    end
  end
end
