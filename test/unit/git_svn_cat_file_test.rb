require_relative '../test_helper'

module OhlohScm::Adapters
  class GitSvnCatFileTest < OhlohScm::Test
    def test_cat_file
      with_git_svn_repository('git_svn') do |git_svn|
        expected = <<-EXPECTED.gsub(/^\s+/, '')
          /* Hello, World! */
          #include <stdio.h>
          main()
          {
            printf("Hello, World!\\n");
          }
        EXPECTED

        assert_equal expected, git_svn.cat_file(OhlohScm::Commit.new(token: 1),
                                                OhlohScm::Diff.new(path: 'helloworld.c')).gsub(/\t/, '')
      end
    end

    def test_cat_file_with_non_existent_token
      with_git_svn_repository('git_svn') do |git_svn|
        assert_raise RuntimeError do
          git_svn.cat_file(OhlohScm::Commit.new(token: 999), OhlohScm::Diff.new(path: 'helloworld.c')) .must_raise
        end
      end
    end

    def test_cat_file_with_invalid_filename
      with_git_svn_repository('git_svn') do |git_svn|
        refute git_svn.cat_file(OhlohScm::Commit.new(token: 1), OhlohScm::Diff.new(path: 'invalid'))
      end
    end

    def test_cat_file_parent
      with_git_svn_repository('git_svn') do |git_svn|
        expected = <<-EXPECTED.gsub(/^\s+/, '')
          /* Hello, World! */
          #include <stdio.h>
          main()
          {
            printf("Hello, World!\\n");
          }
        EXPECTED

        assert_equal expected, git_svn.cat_file_parent(OhlohScm::Commit.new(token: 2),
                                                       OhlohScm::Diff.new(path: 'helloworld.c')).gsub(/\t/, '')
      end
    end

    def test_cat_file_parent_with_first_token
      with_git_svn_repository('git_svn') do |git_svn|
        refute git_svn.cat_file_parent(OhlohScm::Commit.new(token: 1), OhlohScm::Diff.new(path: 'helloworld.c'))
      end
    end
  end
end
