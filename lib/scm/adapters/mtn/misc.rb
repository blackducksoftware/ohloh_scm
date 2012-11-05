# -*- coding: undecided -*-
module Scm::Adapters
  class MtnAdapter < AbstractAdapter
    def exist?
      begin
        !!(head_token)
      rescue
        logger.debug { $! }
        false
      end
    end

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
  end
end
