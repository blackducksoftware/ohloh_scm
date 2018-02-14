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

    def test_export_works_identically_for_tag_or_commit_sha
      with_git_repository('git') do |git|
        tag_sha = 'f6e5a894ac4173f8f2a200f2c36df38a1e61121a'
        commit_sha = `cd #{ git.url } && git show #{ tag_sha }`.slice(/commit (.+)$/, 1)

        OhlohScm::ScratchDir.new do |tag_dir|
          git.export(tag_dir, tag_sha)

          OhlohScm::ScratchDir.new do |commit_dir|
            git.export(commit_dir, commit_sha)

            assert_equal '', `diff -rq #{ tag_dir } #{ commit_dir }`
            assert_equal ['.','..','.gitignore','helloworld.c','makefile','ohloh_token'], Dir.entries(commit_dir).sort
          end
        end
      end
    end

		def test_branches
			with_git_repository('git') do |git|
				assert_equal ['develop', 'master'], git.branches
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

    def test_fixture_repo_has_dereferenced_tags
      with_git_repository('git') do |git|
        tag_shas = git.run("cd #{git.url} && git tag --format='%(objectname)' | sed 's/refs\\/tags\\///'").split(/\n/)
        assert_equal true, tag_shas.any? { |sha| not git.commit_tokens.include?(sha) }
      end
    end

    def test_tags
      with_git_repository('git') do |git|
        assert_equal git.tags, [['v1.0.0', 'b6e9220c3cabe53a4ed7f32952aeaeb8a822603d', Time.parse('2016-07-31T07:58:30+05:30')],
                                ['v1.1.0-lw', '2e9366dd7a786fdb35f211fff1c8ea05c51968b1', Time.parse('2006-06-11T11:34:17-07:00')],
                                ['v2.1.0', '1df547800dcd168e589bb9b26b4039bff3a7f7e4', Time.parse('2006-07-14T16:07:15-07:00')]]
      end
    end

    def test_tags_reference_valid_commits
      with_git_repository('git') do |git|
        tag_shas = git.tags.map { |list| list[1] }
        assert_equal true, tag_shas.all? { |sha| git.commit_tokens.include?(sha) }
      end
    end

    def test_tags_with_non_tagged_repository
      with_git_repository('git_walk') do |git|
        assert_equal git.tags, []
      end
    end

    def test_tags_having_tagname_master
      with_git_repository('git_with_master_tag') do |git|
        assert_equal git.tags, [['master', '4e95717ac8cff8cdb10d83398d3ac667a2cca341', Time.parse('2018-02-01T12:56:48+0530')]]
      end
    end
	end
end
