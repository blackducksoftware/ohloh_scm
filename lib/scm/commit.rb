module Scm
	# A commit is a collection of diffs united by a single timestamp, author, and
	# message.
	#
	# Ohloh's internal data model assumes that commits are immutable, and exist
	# in a singly-linked list. That is, commits can be nicely numbered a la
	# Subversion, and new commits are always added to the end of the list.
	#
	# This works for CVS and Subversion, but unfortunately, does not at all map
	# to the DAG used by Git, which allows a commit to have multiple parents and
	# children, and which allows new commits to appear during a pull which have
	# timestamps older than previously known commits.
	#
	# This means that Ohloh's support for systems like Git is crude at best. For
	# the near future, it is the job of the adapter to make the Git commit chain
	# appear as much like a single array as possible.
	#
	# For Darcs, it is assumed the repo's patch ordering is never changed.
	#
	class Commit
		# This object supports the idea of distinct authors and committers, a la
		# Git.  However, Ohloh will retain only one of them in its database. It
		# prefers author, but will fall back to committer if no author is given.
		attr_accessor :author_name, :author_email, :author_date, :committer_name, :committer_email, :committer_date

		attr_accessor :message

		attr_accessor :diffs

		# The token is used to uniquely identify a commit, and can be any type of
		# adapter-specific data.
		#
		# For Subversion, the token is the revision number.
		# For Git, the token is the commit SHA1 hash.
		# For CVS, which does not support atomic commits with unique IDs, we use
		# the approximate timestamp of the change.
		# For Darcs, the token is the patch name, and it may not be unique. XXX
		attr_accessor :token

		# A pointer back to the adapter that contains this commit.
		attr_accessor :scm

		# Hack. To optimize CVS updates, we will store the names of all the
		# directories that require updating during this commit. Ohloh itself never
		# actually sees this.
		attr_accessor :directories

		def initialize(params={})
			params.each { |k,v| send(k.to_s + '=', v) if respond_to?(k.to_s + '=') }
		end
	end
end
