module Scm::Adapters
  class MtnAdapter < AbstractAdapter
    #This attribute allows to provide the database filepath instead
    # of using default database
    attr_accessor :database
    
    def initialize(params={})
      super(params)
    end
    
    def english_name
      "Monotone"
    end

    def database
      if @database.nil? then
        #Try to find from the working copy if url is file or 
        #without scheme
        if self.local? then
          self.get_database
        else
          #It's a remote repository, we don't have a database
          self.database = ''
        end
      end
      @database
    end

    # this setter splits the url if a branch name is found according to regexp
    def url=(u)
      matchData = /^(mtn|ssh|file):\/\/\/{0,1}(\w+@)?[A-Za-z0-9_\-\.]+(:\d+)?\/[A-Za-z0-9_\-\.\/\~\+]*\?([A-Za-z0-9_\-\.\/\~\+]+)$/.match(u)
      if matchData.nil?() == false then
        @branch_name = $4
        offsets = matchData.offset(4)
        #we remove two characters because of ? character
        @url = u[0..offsets[0] - 2]
      else
        @url = u
      end
    end

  end
end

require 'lib/scm/adapters/mtn/misc'
require 'lib/scm/adapters/mtn/commits'
require 'lib/scm/adapters/mtn/pull'
require 'lib/scm/adapters/mtn/head'
require 'lib/scm/adapters/mtn/cat_file'
require 'lib/scm/adapters/mtn/patch'
require 'lib/scm/adapters/mtn/push'
