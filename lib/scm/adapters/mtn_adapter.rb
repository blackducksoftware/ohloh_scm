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
  end
end

require 'lib/scm/adapters/mtn/misc'
require 'lib/scm/adapters/mtn/commits'
require 'lib/scm/adapters/mtn/pull'
require 'lib/scm/adapters/mtn/head'
require 'lib/scm/adapters/mtn/cat_file'
require 'lib/scm/adapters/mtn/patch'
require 'lib/scm/adapters/mtn/push'
