module Scm::Adapters
	class BzrlibAdapter < BzrAdapter

		def cat(revision, path)
      content = bzr_client.cat_file(revision, path)
		end

	end
end
