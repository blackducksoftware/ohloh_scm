require 'spec_helper'

describe 'Git::Status' do
  it 'branch?' do
    with_git_repository('git') do |git|
      git.activity.send(:branches).must_equal %w[develop master]
      assert git.status.branch?('master')
      assert git.status.branch?('develop')
    end
  end

  describe 'default_branch' do
    it 'must return default branch when repository doesnt exist' do
      git = OhlohScm::Factory.get_core(scm_type: :git, url: 'foobar')
      git.status.stubs(:exist?)
      _(git.status.default_branch).must_equal 'master'
    end

    it 'must return default branch when no HEAD branch is found in remote' do
      git = OhlohScm::Factory.get_core(scm_type: :git, url: 'foobar')
      git.status.stubs(:exist?).returns(true)
      git.status.default_branch.must_equal 'master'
    end
  end
end
