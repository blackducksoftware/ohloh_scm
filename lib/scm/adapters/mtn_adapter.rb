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
      if @database.nil? or @database == '' then
        #Try to find from the working copy if url is without scheme
        # with scheme denotes a "remote" server
        if self.url == self.path then
          begin
            self.get_database
          rescue
            # It failed because we don't have a working copy, so set it to :default
            logger.info "Did not find any database, falling back to :default"
            @database = ':default'
          end
        else
          #It's a remote repository, we don't have a database
          logger.info "This is a remote repository to pull from, we don't need a database file."
          @database = ''
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

    # As for database, if we don't have the branch name
    # We try to find it in the working copy
    def branch_name
      if @branch_name.nil?() == true or @branch_name == '' then
        #Try to find from the working copy if url is without scheme
        # with scheme denotes a "remote" server
        if self.url == self.path then
          begin
            @branch_name = self.get_branch_name
          rescue
            logger.info "No workspace found"
          end
        end
      end
      @branch_name
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
