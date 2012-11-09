# -*- coding: undecided -*-
module Scm::Adapters
  class MtnAdapter < AbstractAdapter

    #Allow to see if a local working copy exists
    def exist?
      begin
        !!(head_token)
      rescue
        logger.debug { $! }
        false
      end
    end

    #Use this to export the content
    #Warning, the dest_dir will not contain directly content but a directory holding it
    def export(dest_dir, commit_id = 'h:')
      if commit_id == 'h:' then
        commit_id = "h:#{self.branch_name}"
      end
      # Real destination dir will be nested inside
      real_co_dir = File.join(dest_dir, self.branch_name)

      #Admin directory
      admin_dir = File.join(real_co_dir, '_MTN')
      run "cd #{url} && mtn co --revision #{commit_id} #{real_co_dir} && rm -rf #{admin_dir}"
    end
    
    #Use this to get the tree content
    # By default, monotone takes head of the branch
    def ls_tree(token='')
      log = run("cd #{url} && mtn automate get_manifest_of #{token}")
      files = []
      # Just parse the log
      log.each_line do |line|
        case line
          # Deals only with files, not directory nor SHA1 content
        when /^\s+file\s+\"(.+)\"$/
          files << $1
        end
      end
      return files
    end
    
    #Allow to test if a remote copy exists
    def remote_exist?
      begin
        # NOTE : we don't have a local working copy, use remote to get the head token
        # token = run("mtn automate remote --remote-stdio-host=#{url} heads -q #{branch_name}")
        # As The previous command requires to have a key (and a .monotone folder), we use the following
        log = run("mtn automate pull --dry-run '#{self.url}?#{self.branch_name}'")
        # if it succeeds, find if there are revisions
        log.each_line do |line|
          case line
            when /^receive_revision\s+\"([0-9]+)\"$/
            number = $1.to_i
            if number > 0 then
              return true
            else
              return false
            end
          end
        end
      rescue
        logger.debug { $! }
        false
      end
    end

    # Retrieve the database path from a working copy if existing
    def get_database
      log = run("grep database #{self.url}/_MTN/options")
      log.each_line do |database_line|
        if database_line =~ /database "(.+)"/i then
          self.database = $1
        end
      end
    end

    def get_branch_name
      log = run("cd #{self.url} && mtn automate get_option branch").chomp
    end
  end
end
