module OhlohScm::Adapters
	class AbstractAdapter
		attr_accessor :url, :branch_name, :username, :password, :errors, :public_urls_only
    attr_writer :temp_folder

		def initialize(params={})
			params.each { |k,v| send(k.to_s + '=', v) if respond_to?(k.to_s + '=') }
		end

		# Handy for test overrides
		def metaclass
			class << self
				self
			end
		end
    def temp_folder
      @temp_folder || '/tmp'
    end
	end
end

require_relative 'abstract/system'
require_relative 'abstract/validation'
require_relative 'abstract/sha1'
require_relative 'abstract/misc'
