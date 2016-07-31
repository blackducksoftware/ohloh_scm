require_relative '../test_helper'

module OhlohScm::Adapters
	class GitMiscTest < OhlohScm::Test

		def test_export
			with_git_repository('git') do |git|
				OhlohScm::ScratchDir.new do |dir|
					git.export(dir)
					assert_equal ['.','..','.gitignore','COPYING','README','helloworld.c','makefile','ohloh_token'], Dir.entries(dir).sort
				end
			end
		end

		def test_branches
			with_git_repository('git') do |git|
				assert_equal ['master'], git.branches
				assert git.has_branch?('master')
			end
		end

		def test_ls_tree
			with_git_repository('git') do |git|
				assert_equal ['.gitignore','COPYING','README','helloworld.c','makefile','ohloh_token'], git.ls_tree(git.head_token).sort
			end
		end

		def test_is_merge_commit
			with_git_repository('git_walk') do |git|
				assert git.is_merge_commit?(OhlohScm::Commit.new(:token => 'f264fb40c340a415b305ac1f0b8f12502aa2788f'))
				assert !git.is_merge_commit?(OhlohScm::Commit.new(:token => 'd067161caae2eeedbd74976aeff5c4d8f1ccc946'))
			end
		end

    def test_branches_encoding
      with_git_repository('git_with_invalid_encoding') do |git|
        assert_equal true, git.branches.all? { |branch| branch.valid_encoding? }
      end
    end

    # `git ls-tree` returns filenames in valid utf8 regardless of their original form.
    def test_ls_tree_encoding
      with_git_repository('git_with_invalid_encoding') do |git|
        assert_equal true, git.ls_tree.all? { |filename| filename.valid_encoding? }
      end
    end
	end
end
