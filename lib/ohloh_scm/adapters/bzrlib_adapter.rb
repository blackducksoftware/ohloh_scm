require 'rubygems'

require_relative 'bzrlib/bzrlib_pipe_client'
module OhlohScm::Adapters
	class BzrlibAdapter < BzrAdapter

    def setup
      bzr_client = BzrPipeClient.new(url)
      bzr_client.start
      bzr_client
    end

    def bzr_client
      @bzr_client ||= setup
    end

    def cleanup
      @bzr_client.shutdown
    end

	end
end

require_relative 'bzrlib/head'
require_relative 'bzrlib/cat_file'
