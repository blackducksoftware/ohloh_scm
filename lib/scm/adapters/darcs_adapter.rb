module Scm::Adapters
	class DarcsAdapter < AbstractAdapter
		def english_name
			"Darcs"
		end
	end
end

require 'lib/scm/adapters/darcs/validation'
require 'lib/scm/adapters/darcs/cat_file'
require 'lib/scm/adapters/darcs/commits'
require 'lib/scm/adapters/darcs/misc'
require 'lib/scm/adapters/darcs/pull'
require 'lib/scm/adapters/darcs/push'
require 'lib/scm/adapters/darcs/head'
require 'lib/scm/adapters/darcs/patch'
