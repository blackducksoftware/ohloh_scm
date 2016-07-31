module OhlohScm
	# A +Diff+ represents a change to a single file. It can represent the addition or
	# deletion of a file, or it can represent a modification of the file contents.
	#
	# Ohloh does not track filename changes. If a file is renamed, Ohloh treats this
	# as the deletion of one file and the creation of another.
	#
	# Ohloh does not track directories, only the files within directories.
	#
	# Don't confuse our use of the word "Diff" with a patch file or the output of the
	# console tool 'diff'. This object doesn't have anything to do the actual contents
	# of the file; it's better to think of this object as representing a single line
	# item from a source control log.
	class Diff
		# The filename of the changed file, relative to the root of the repository.
		attr_accessor :path

		# An action code describing the type of change made to the file.
		# Action codes are copied directly from the Git standard.
		# The action code can be...
		#   'A' added
		#   'M' modified
		#   'D' deleted
		attr_accessor :action

		# The SHA1 hash of the file contents both before and after the change.
		# These must be computed using the same method as Git.
		attr_accessor :parent_sha1, :sha1

		# For Subversion only, a path may be reported as copied from another location.
		# These attributes store the path and revision number of the source of the copy.
		attr_accessor :from_path, :from_revision

		def initialize(params={})
			params.each { |k,v| send(k.to_s + '=', v) if respond_to?(k.to_s + '=') }
		end

		# eql?() and hash() are implemented so that [].uniq() will work on an array of Diffs.
		def eql?(a)
			@action.eql?(a.action) && @path.eql?(a.path) && @sha1.eql?(a.sha1) && @parent_sha1.eql?(a.parent_sha1)
		end

		def hash
			"#{action}|#{path}|#{sha1}|#{parent_sha1}".hash
		end
	end
end
