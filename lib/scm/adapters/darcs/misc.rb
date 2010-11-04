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
			run("cd '#{path}' && darcs manifest -r #{token}").split("\n")
		end

		def export(dest_dir, token='tip')
			run("cd '#{path}' && darcs archive -r #{token} '#{dest_dir}'")
			# Darcs leaves a little cookie crumb in the export directory. Remove it.
			File.delete(File.join(dest_dir, '.darcs_archival.txt')) if File.exist?(File.join(dest_dir, '.darcs_archival.txt'))
		end
	end
end
