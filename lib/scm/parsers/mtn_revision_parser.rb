# -*- coding: undecided -*-
module Scm::Parsers
  # This parser can process the mtn revision log from 'automate get_revision' command
  class MtnRevisionParser < Parser
    def self.scm
      'mtn revision'
    end
    
    def self.internal_parse(buffer, opts)
      e = nil
      state = :none
      
      buffer.each_line do |l|
          case l
          when /^delete\s+\"(.+)\"$/
            #Something was deleted
            e = Scm::Diff.new
            e.path = $1
            e.action = 'D'
            yield e if block_given?

          when /^rename\s+\"(.+)\"$/
            #A file or directory was renamed
            state = :rename
            # We create a new diff to track the deletion of the file
            # before rename
            e = Scm::Diff.new
            e.path = $1
            e.action = 'D'
            yield e if block_given?

          when /^\s+from\s+\[(.+)\]$/
            if state == :patch and e.nil? == false then
              e.parent_sha1 = $1
              state = :patch_from
            else
              state = :none
            end

          when /^\s+to\s+\"(.+)\"$/
            if state == :rename then
              # We create a new diff to track the addition of file
              e = Scm::Diff.new
              e.path = $1
              e.action = 'A'
              state = :none
                        
              yield e if block_given?
            end
           
          when /^\s+to\s+\[(.+)\]$/
            #This is a "to" for patch :)
            if state == :patch_from and e.nil? == false then
              e.sha1 = $1
              state = :none

              yield e if block_given?
            end

          when /^add_dir\s+\"(.+)\"$/
            #We found a directory add but Ohloh don't care
            #But we will do nothing with it

          when /^add_file\s+\"(.+)\"$/
            #A new file was added
            e = Scm::Diff.new
            e.path = $1
            e.action = 'A'
            state = :add

          when /^\s+content\s+\[(.+)\]$/
            # This is the content sha1 sig for added file
            if state == :add and e.nil? == false then
              e.sha1 = $1
            end
            yield e if block_given?

          when /^patch\s+\"(.+)\"$/
            #A file was modified
            e = Scm::Diff.new
            e.path = $1
            e.action = 'M'
            state = :patch

          when /^clear\s+\"(.+)\"$/
            #An attribute on file was modified
            
          when /^set\s+\"(.+)\"$/
            #An attribute was set on a file
          end
      end
    end
  end
end
