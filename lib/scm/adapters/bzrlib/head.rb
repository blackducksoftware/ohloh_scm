module Scm::Adapters
	class BzrlibAdapter < BzrAdapter

		def parent_tokens(commit)
      bzr_client.parent_tokens(commit.token)
		end

	end
end
