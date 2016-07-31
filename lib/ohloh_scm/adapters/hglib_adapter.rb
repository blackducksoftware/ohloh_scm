require 'rubygems'
require_relative 'hglib/client'

module OhlohScm::Adapters
	class HglibAdapter < HgAdapter

    def setup
      hg_client = HglibClient.new(url)
      hg_client.start
      hg_client
    end

    def hg_client
      @hg_client ||= setup
    end

    def cleanup
      @hg_client && @hg_client.shutdown
    end

	end
end

require_relative 'hglib/head'
require_relative 'hglib/cat_file'
