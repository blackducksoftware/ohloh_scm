module Scm::Adapters
	class DarcsAdapter < AbstractAdapter
		def head_token
			# This only returns first 12 characters.
			# How can we make it return the entire hash?
			token = run("darcs id -q #{url}").strip

			# Recent versions of Darcs now somtimes append a '+' char to the token.
			# I believe this signifies pending changes... but we don't care.
			# Strip the trailing '+', if any.
			token = token[0..-2] if token[-1..-1] == '+'

			token
		end

		def head
			verbose_commit(head_token)
		end

		def parent_tokens(commit)
			run("cd '#{url}' && darcs parents -r #{commit.token} --template '{node}\\n'").split("\n")
		end

		def parents(commit)
			parent_tokens(commit).collect { |token| verbose_commit(token) }
		end
	end
end
