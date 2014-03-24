module Scm::Adapters
	class DarcsAdapter < AbstractAdapter
		def exist?
			begin
				!!(head_token)
			rescue
				logger.debug { $! }
				false
			end
		end

		def ls_tree(token)
			run("cd '#{path}' && darcs show files -p '#{token}'").split("\n")
		end

		def export(dest_dir, token=nil)
			p = token ? " -p '#{token}'" : ""
			run("cd '#{path}' && darcs dist#{p} && mv darcs.tar.gz '#{dest_dir}'")
		end
	end
end
