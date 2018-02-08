module OhlohScm::Adapters
  class GitSvnAdapter < AbstractAdapter
    def commit_count(opts={})
      cmd = "#{after_revision(opts)} | wc -l"
      git_svn_log(cmd: cmd, oneline: true).to_i
    end

    def commits(opts={})
      parsed_commits = []
      open_log_file(opts) do |io|
        parsed_commits = OhlohScm::Parsers::SvnParser.parse(io)
      end
      parsed_commits.reverse
    end

    def commit_tokens(opts={})
      cmd = "#{after_revision(opts)} | #{extract_revision_number}"
      git_svn_log(cmd: cmd, oneline: true).split
        .map(&:to_i)
        .reverse
    end

    def each_commit(opts={})
      commits(opts).each do |commit|
        yield commit
      end
    end

    private

    def open_log_file(opts={})
      cmd = "-v | #{string_encoder} > #{log_filename}"
      git_svn_log(cmd: cmd, oneline: false)
      File.open(log_filename, 'r') { |io| yield io }
    end

    def log_filename
      File.join('/tmp', url.gsub(/\W/,'') + '.log')
    end

    def after_revision(opts)
      after_token = (opts[:after] || 0).to_i
      "-r#{after_token}:#{head_token}"
    end

    def head_token
      cmd = "--limit=1 | #{extract_revision_number}"
      git_svn_log(cmd: cmd, oneline: true)
    end

    def extract_revision_number
      "cut -d '|' -f1 | cut -c 2-"
    end
  end
end
