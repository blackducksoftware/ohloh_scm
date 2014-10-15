module OhlohScm::Adapters
	class DarcsAdapter < AbstractAdapter
		def english_name
			"Darcs"
		end
	end
end

require_relative 'darcs/validation'
require_relative 'darcs/cat_file'
require_relative 'darcs/commits'
require_relative 'darcs/misc'
require_relative 'darcs/pull'
require_relative 'darcs/push'
require_relative 'darcs/head'
require_relative 'darcs/patch'
