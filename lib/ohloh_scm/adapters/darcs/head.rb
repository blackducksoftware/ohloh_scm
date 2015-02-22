module OhlohScm::Adapters
	class DarcsAdapter < AbstractAdapter
		def head_token
		  string_to_patch_tokens(run("cd '#{url}' && darcs changes --last 1"))[0]
		end

		def head
			verbose_commit(head_token)
		end

		def parent_tokens(commit)
		  string_to_patch_tokens(run("cd '#{url}' && darcs changes --to-match 'hash #{commit.token}'"))[1..-1]
		end

		def parents(commit)
			parent_tokens(commit).map {|token| verbose_commit(token)}
		end

		def string_to_patch_tokens(s)
		  s.split(/\n/).select {|s| s =~ /^patch /}.map {|s| s.sub(/^patch /,'')}
		end
	end
end
