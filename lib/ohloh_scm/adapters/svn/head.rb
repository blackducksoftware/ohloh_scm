module OhlohScm::Adapters
	class SvnAdapter < AbstractAdapter
		def head_token
			self.info =~ /^Revision: (\d+)$/ ? $1.to_i : nil
		end

		def head
			verbose_commit("HEAD")
		end

		def parents(commit)
			# Subversion doesn't have an actual "parent" command, so get
			# a log for this commit and the one preceding it, and keep only the preceding.
			log = run "svn log --trust-server-cert --non-interactive --verbose --xml --stop-on-copy -r #{commit.token}:1 --limit 2 '#{SvnAdapter.uri_encode(self.url)}' #{opt_auth}"
			[deepen_commit(strip_commit_branch(OhlohScm::Parsers::SvnXmlParser.parse(log).last))]
		end
	end
end

