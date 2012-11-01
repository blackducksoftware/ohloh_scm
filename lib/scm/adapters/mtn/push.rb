module Scm::Adapters
  class MtnAdapter < AbstractAdapter

    # Just as for pull, it can be interesting to provide several info depending on local or remote
    # if "to" is supposed to be local, its url field must point to a local database file using file:// scheme
    # if "to" is remote, standard url must be provided
    def push(to, &block)
      raise ArgumentError.new("Cannot push to #{to.inspect}") unless to.is_a?(MtnAdapter)
      logger.info { "Pushing to #{to.url}" }

      yield(0,1) if block_given? # Progress bar callback

      unless to.exist?
        if to.local?
          # Create a new repo on the same local machine. Just use existing pull code in reverse.
          # Not really useful
          to.pull(self)
        else
          # This one is difficult. What are we supposed to do
          # Just copying the database on a remote server ?
          #
          #run "ssh #{to.hostname} 'mkdir -p #{to.path}'"
          #run "scp -rpqB #{hg_path} #{to.hostname}:#{to.path}"
        end
      else
        # This one is easy, just push the standard way
        run "cd '#{self.url}' && mtn push '#{to.url}'"
      end

      yield(1,1) if block_given? # Progress bar callback
    end

    def local?
      return true if hostname == Socket.gethostname
      return true if url =~ /^file:\/\//
      return true if url !~ /:/
      false
    end

    def hostname
      $1 if url =~ /^(ssh|mtn):\/\/([^\/]+)/
    end

    def path
      case url
      when /^file:\/\/(.+)$/
        $1
      when /^ssh:\/\/[^\/]+(\/.+)$/
        $1
      when /^[^:]*$/
        url
      end
    end

    def hg_path
      path && File.join(path, '.hg')
    end
  end
end
