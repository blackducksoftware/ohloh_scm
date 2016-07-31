require_relative '../test_helper'

module OhlohScm::Adapters
	class GitCommitAllTest < OhlohScm::Test

		def test_commit_all
			OhlohScm::ScratchDir.new do |dir|
				git = GitAdapter.new(:url => dir).normalize

				git.init_db
				assert !git.anything_to_commit?

				File.open(File.join(dir, 'README'), 'w') {}
				assert git.anything_to_commit?

				c = OhlohScm::Commit.new
				c.author_name = "John Q. Developer"
				c.message = "Initial checkin."
				git.commit_all(c)
				assert !git.anything_to_commit?

				assert_equal 1, git.commits.size

				assert_equal c.author_name, git.commits.first.author_name
				# Depending on version of Git used, we may or may not have trailing \n.
				# We don't really care, so just compare the stripped versions.
				assert_equal c.message.strip, git.commits.first.message.strip

				assert_equal ['.gitignore', 'README'], git.commits.first.diffs.collect { |d| d.path }.sort
			end
		end

	end
end
