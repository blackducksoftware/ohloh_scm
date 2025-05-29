require 'spec_helper'

describe 'GitSvn::Scm' do
  it 'must convert to git Repository' do
    with_svn_repository('svn') do |src|
      tmpdir do |local_dir|
        git_svn = get_core(:git_svn, url: local_dir)
        git_svn.scm.pull(src.scm, TestCallback.new)
        assert git_svn.status.exist?

        assert_equal git_svn.activity.commit_count, 5
      end
    end
  end

  it 'must fetch the repo' do
    OhlohScm::GitSvn::Scm.any_instance.expects(:run).times(3)
    with_git_svn_repository('git_svn') do |git_svn|
      git_svn.scm.pull(git_svn.scm, TestCallback.new)
    end
  end
end
