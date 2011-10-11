require 'rubygems'
require 'rubypython'

require 'lib/scm/adapters/bzrlib/bzrlib_pipe_client'
module Scm::Adapters
	class BzrlibAdapter < BzrAdapter

    def setup
      @bzr_client = BzrPipeClient.new(url)
      @bzr_client.start
    end

    def bzr_client
      setup unless @bzr_client
      return @bzr_client
    end

    def cleanup
      @bzr_client.shutdown
    end

	end
end

require 'lib/scm/adapters/bzrlib/head'
require 'lib/scm/adapters/bzrlib/cat_file'
