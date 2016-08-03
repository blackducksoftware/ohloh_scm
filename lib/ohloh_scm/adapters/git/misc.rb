module OhlohScm::Adapters
	class GitAdapter < AbstractAdapter
		def git_path
			File.join(self.url, '/.git')
		end

		def exist?
			begin
				!!(head_token)
			rescue
				logger.debug { $! }
				false
			end
		end

		def export(dest_dir, commit_id = 'HEAD')
			run "cd #{url} && git archive #{commit_id} | tar -C #{ dest_dir } -x"
		end

		def ls_tree(token='HEAD')
			run("cd #{url} && git ls-tree -r #{token} | cut -f 2 -d '\t'").split("\n")
		end

    # For a given commit ID, returns the SHA1 hash of its tree
    def get_commit_tree(token='HEAD')
      run("cd #{url} && git cat-file commit #{token} | grep '^tree' | cut -d ' ' -f 2").strip
    end

		# Moves us the correct branch and checks out the most recent files.
		#
		# Anything not tracked by Git is deleted.
		#
		# This method may not seem like the most efficient way to accomplish this,
		# but we need very high reliability and this sequence gets the job done every time.
		def checkout
			if FileTest.exist? git_path
				run "cd '#{url}' && git clean -f -d -x"
				if self.has_branch?
					run "cd '#{url}' && git reset --hard #{self.branch_name} --"
					run "cd '#{url}' && git checkout #{self.branch_name} --"
				end
			end
		end

		#---------------------------------------------------------------------------
		# BRANCH-RELATED CODE
		#-------------------------------------------------------------------------

		# Returns an array of all branch names
		def branches
			run("cd '#{self.url}' && git branch | #{ string_encoder }").split.collect { |b| b =~ /\b(.+)$/ ; $1 }.compact
		end

		def has_branch?(name=self.branch_name)
			return false unless FileTest.exist?(self.git_path)
			self.branches.include?(name)
		end

		# Create a new local branch to mirror the remote one
		# If a branch of this name already exist, nothing happens.
		def create_tracking_branch(name)
			return if name.to_s == ''

			unless self.branches.include? name
				run "cd '#{self.url}' && git branch -f #{name} origin/#{name}"
			end
		end

		def is_merge_commit?(commit)
			parent_tokens(commit).size > 1
		end

    def tags
      tag_strings = run("cd #{url} && git show-ref --tags").split(/\n/)
      tags_and_revs = tag_strings.map do |tag_string|
        commit_hash, tag_path = tag_string.split(/\s/)
        tag_name = tag_path.gsub('refs/tags/', '')
        [tag_name, commit_hash]
      end

      Hash[tags_and_revs]
    end
	end
end
