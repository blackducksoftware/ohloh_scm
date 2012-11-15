# -*- coding: undecided -*-
module Scm::Parsers
  # This parser can process the default mtn logs
  class MtnCertsParser < Parser
    def self.scm
      'mtn'
    end
    
    def self.internal_parse(buffer, opts)
      e = nil
      diff = nil
      unfinished = false
      state = :none
      
      buffer.each_line do |l|
          case l
          when /^\s+key\s+\[([a-z0-9]+)\]$/
            #we began a new cert key/value pair
            #            yield e if e && block_given? && $1 != e.token
            if e.nil? == true then
              e = Scm::Commit.new
            end
            state = :key

          when /^\s+signature\s+\"(ok|bad|unknown)\"$/
            #We found a signature result
            #But we will do nothing with it

          when /^\s+name\s+\"(.+)\"$/
            case $1
            when "author"
              state = :author
              
            when "date"
              state = :date
              
            when "changelog"
              state = :changelog
            end
            
            #We don't put the enclosing quote as in changelog case
            #value can be multiline
          when /^\s+value\s+\"(.+)$/
            case state 
            when :changelog
              # no ending " in string then it's unfinished
              if $1[$1.length - 1 ] != 34 then
                e.message = $1
                unfinished = true
              else
                e.message = $1[0, $1.length-1]
              end

            when :author
              name = $1
              if $1[$1.length - 1] == 34 then
                name = $1[0, $1.length - 1]
              end
              #Trying to separate if there's two parts
              if /(.+)<(.+)>/.match(name) then
                e.author_email = $2.chomp
                e.author_name = $1.chomp
              else
                e.author_name = name
                e.author_email = name
              end

            when :date
              date = $1
              if $1[$1.length - 1] == 34 then
                date = $1[0, $1.length - 1]
              end
              date = date + "+00:00" 
              
              e.author_date = Time.parse(date).utc
            end
            
          when /^\s+trust\s+"(.+)"$/
            #we do nothing with trusted flag
            unfinished = false
            state = :trust
          else
            #It's not a basicIO keyword so it's the continuation of a previous line
            if state ==:changelog
              if unfinished == true then
                string = l
                if l[l.length - 2] == 34 then
                  string = l[0, l.length - 2]
                  unfinished = false
                end
                e.message = e.message + string
              end
            end
          end
      end
      yield e if e && block_given?
    end
  end
end
