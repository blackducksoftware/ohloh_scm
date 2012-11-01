module Scm::Adapters
  class MtnAdapter < AbstractAdapter
    #This attribute allows to provide the database filepath instead
    # of using default database
    attr_accessor :database
    
    def initialize(params={})
      super(params)
      @database=''
    end
    
    def english_name
      "Monotone"
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
