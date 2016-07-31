require_relative '../test_helper'

module OhlohScm::Adapters
	class GitTokenTest < OhlohScm::Test

		def test_no_token_returns_nil
			OhlohScm::ScratchDir.new do |dir|
				git = GitAdapter.new(:url => dir).normalize
				assert !git.read_token
				git.init_db
				assert !git.read_token
			end
		end

		def test_write_and_read_token
			OhlohScm::ScratchDir.new do |dir|
				git = GitAdapter.new(:url => dir).normalize
				git.init_db
				git.write_token("FOO")
				assert !git.read_token # Token not valid until committed
				git.commit_all(OhlohScm::Commit.new)
				assert_equal "FOO", git.read_token
			end
		end

		def test_commit_all_includes_write_token
			OhlohScm::ScratchDir.new do |dir|
				git = GitAdapter.new(:url => dir).normalize
				git.init_db
				c = OhlohScm::Commit.new
				c.token = "BAR"
				git.commit_all(c)
				assert_equal c.token, git.read_token
			end
		end

    def test_read_token_encoding
      with_git_repository('git_with_invalid_encoding') do |git|
        assert_nothing_raised do
          git.read_token
        end
      end
    end
	end
end
