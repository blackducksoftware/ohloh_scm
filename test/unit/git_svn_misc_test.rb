require_relative '../test_helper'

module OhlohScm::Adapters
  class GitSvnCommitsTest < OhlohScm::Test
    def test_exist
      with_git_svn_repository('git_svn') do |git_svn|
        assert git_svn.exist?
      end
    end

    def test_export
      with_git_svn_repository('git_svn') do |git_svn|
        OhlohScm::ScratchDir.new do |dir_path|
          assert_equal `ls #{ dir_path }`, ''
          git_svn.export(dir_path, 2)
          assert_equal `ls #{ dir_path }`.split(/\n/), ['helloworld.c', 'makefile']
        end
      end
    end

    def test_export_without_arguments
      with_git_svn_repository('git_svn') do |git_svn|
        OhlohScm::ScratchDir.new do |dir_path|
          assert_equal `ls #{ dir_path }`, ''
          git_svn.export(dir_path)
          assert_equal `ls #{ dir_path }`.split(/\n/), ['COPYING', 'helloworld.c', 'makefile', 'README']
        end
      end
    end
  end
end
