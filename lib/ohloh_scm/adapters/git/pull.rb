module OhlohScm::Adapters
	class GitAdapter < AbstractAdapter

		def pull(from, &block)
			logger.info { "Pulling #{from.url}" }
			case from
			when GitAdapter
				clone_or_fetch(from, &block)
			when CvsAdapter, SvnAdapter
				convert(from, &block)
			end
		end

		# Clone source_scm as new repository.
		# If a local repository already exists, update the local repository with the latest changes.
		def clone_or_fetch(source_scm)
			raise ArgumentError.new("Cannot pull from #{source_scm.inspect}") unless source_scm.is_a?(GitAdapter)

			yield(0,1) if block_given? # Progress bar callback

			unless self.exist? && self.has_branch?
				run "mkdir -p '#{self.url}'"
				run "rm -rf '#{self.url}'"
				run "git clone -q -n '#{source_scm.url}' '#{self.url}' >/dev/null 2>&1"
				create_tracking_branch(source_scm.branch_name) # ensure the correct branch exist locally
				checkout # switch to the correct branch
			else
				checkout # should already be on correct branch, but some old repositories were stricken by a bug
				run "cd '#{self.url}' && git fetch --update-head-ok '#{source_scm.url}' #{self.branch_name}:#{self.branch_name}"
			end
			clean_up_disk

			yield(1,1) if block_given? # Progress bar callback
		end

		# Apply all recent changes from source_scm, converting to Git in the process.
		#
		# Progress is reported by yielding [current_step, total_steps] pairs to a provided block.
		#
		# There are two design goals here:
		#
		# First, minimize adminstrator burden. The conversion process is
		# idempotent: if it fails, Ohloh's first recourse is always to try again.
		# For this reason, it is important that multiple pulls do not result in
		# duplicate data. No matter how badly a previous attempt may be screwed up
		# the contents on disk, a second attempt should be able to gracefully
		# resume.
		#
		# Second, maximize compatibility with a wild array of public source control
		# servers.  CVS in particular has a broad spectrum of server capabilities.
		# Therefore, this conversion algorithm is brute-force simplicity itself. We
		# require a minimum number of features: a log feature to get the list of
		# commits, and the checkout feature to get the contents of each commit.
		#
		# The basic idea for conversion is that we sequentially check out each
		# revision from the original repository into a local directory, which also
		# happens to be a local Git repository. As each revision is checked out
		# from the original repository, we commit it into the local Git repository.
		# By walking forward through each commit, we build a Git equivalent to the
		# original repository.
		#
		# It's not fast, but it almost always succeeds.
		#
		# The original commit ID (CVS timestamp or Subversion revision number) is
		# stored in a special file called 'ohloh_token' and checked in as part of
		# each Git commit. This enables us to match code to original source
		# commit, and also enables us to pick up where we left off for incremental
		# updates.
		#
		# Only a single branch from the original repository is converted.
		def convert(source_scm)
			yield(0,1) if block_given? # Progress bar callback

			# Any new work to be done since the last time we were here?
      ohloh_token = read_token if git_folder_exists?
      commits = source_scm.commits(:after => ohloh_token.to_i)
			if commits and commits.size > 0
				# Start by making sure we are in a known good state. Set up our working directory.
				clean_up_disk
				checkout

				commits.each_with_index do |r,i|
					yield(i,commits.size) if block_given? # Progress bar callback

					logger.info { "Downloading revision #{r.token} (#{i+1} of #{commits.size})... " }
					begin
						r.scm.checkout(r, url)
					rescue
						logger.error { $!.inspect }
						# If we fail to checkout, it's often because there is junk of some kind
						# in our working directory.
						logger.info { "Checkout failed. Cleaning and trying again..." }
						clean_up_disk
						r.scm.checkout(r, url)
					end

          # Sometimes svn conflicts occur leading to a silent `svn checkout` failure.
          if source_scm.is_a?(SvnAdapter) && SvnAdapter.has_conflicts?(url)
            logger.info { "Working copy has svn conflicts. Cleaning and trying again..." }
            clean_up_disk
            r.scm.checkout(r, url)
          end

					logger.debug { "Committing revision #{r.token} (#{i+1} of #{commits.size})... " }
					commit_all(r)
				end
				yield(commits.size, commits.size) if block_given?
			else
				logger.info { "Already up-to-date." }
			end
		end

		# Deletes everything in the working directory.
		# All pending changes are discarded.
		# Only the hidden git folder will remain.
		def clean_up_disk
			if FileTest.exist? url
				run "cd #{url} && find . -maxdepth 1 -not -name .git -not -name . -print0 | xargs -0 rm -rf --"
			end
		end

    private

    def git_folder_exists?
      FileTest.exists?("#{ url }/.git")
    end
	end
end
