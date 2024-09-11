require 'spec_helper'

describe 'Git::Scm' do
  it 'must pull git repository' do
    with_git_repository('git') do |src_core|
      tmpdir do |dest_dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, url: dest_dir)
        refute core.status.scm_dir_exist?

        core.scm.pull(src_core.scm, TestCallback.new)
        assert core.status.scm_dir_exist?
        assert core.status.exist?
      end
    end
  end

  it 'must pull git repository with multiple branches' do
    # This should not change current/default branch(e.g. master) to point to the branch commit being pulled
    # In this case master should not point to test branch commit
    with_git_repository('git_with_multiple_branch', 'test') do |src_core|
      tmpdir do |dest_dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, url: dest_dir, branch_name: 'test')
        refute core.status.scm_dir_exist?
        core.scm.pull(src_core.scm, TestCallback.new)

        remote_master_branch_sha = `cd #{dest_dir} && git rev-parse origin/master`
        master_branch_sha = `cd #{dest_dir} && git rev-parse master`
        test_branch_sha = `cd #{dest_dir} && git rev-parse test`

        master_branch_sha.wont_equal test_branch_sha
        master_branch_sha.must_equal remote_master_branch_sha
      end
    end
  end

  it 'must checkout a branch which is behind the default' do
    with_git_repository('git_with_multiple_branch') do |src_core|
      tmpdir do |dest_dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, url: dest_dir, branch_name: 'master')
        core.scm.pull(src_core.scm, TestCallback.new)

        src_core.scm.branch_name = 'test'
        core = OhlohScm::Factory.get_core(scm_type: :git, url: dest_dir, branch_name: 'test')
        core.scm.pull(src_core.scm, TestCallback.new)

        remote_master_branch_sha = `cd #{dest_dir} && git rev-parse origin/master`
        remote_test_branch_sha = `cd #{dest_dir} && git rev-parse origin/test`
        master_branch_sha = `cd #{dest_dir} && git rev-parse master`
        test_branch_sha = `cd #{dest_dir} && git rev-parse test`

        master_branch_sha.must_equal remote_master_branch_sha
        test_branch_sha.must_equal remote_test_branch_sha
      end
    end
  end

  it 'must handle file changes in multi branch directory' do
    with_git_repository('git_with_multiple_branch', 'test') do |src_core|
      tmpdir do |dest_dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, url: dest_dir, branch_name: 'test')
        refute core.status.scm_dir_exist?
        core.scm.pull(src_core.scm, TestCallback.new)

        `cd #{dest_dir} && git checkout master`
        `echo 'new change' >> #{dest_dir}/hello.rb`

        core.scm.pull(src_core.scm, TestCallback.new)
      end
    end
  end

  it 'must update branches in local copy' do
    test_branch_name = 'test' # consider that 'test' is the current *main* branch.

    with_git_repository('git_with_multiple_branch', test_branch_name) do |src_core|
      tmpdir do |dest_dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, url: dest_dir, branch_name: test_branch_name)
        core.scm.pull(src_core.scm, TestCallback.new)

        # Emulate a scenario where the local copy doesn't have the current *main* branch.
        `cd #{dest_dir} && git checkout master && git branch -D test`

        local_branch_cmd = "cd #{dest_dir} && git branch | grep '\*' | sed 's/^\* //'"
        `#{ local_branch_cmd }`.chomp.must_equal 'master'

        # On doing a refetch, our local copy will now have the updated *main* branch.
        core.scm.pull(src_core.scm, TestCallback.new)
        `#{ local_branch_cmd }`.chomp.must_equal test_branch_name
      end
    end
  end

  it 'must test the basic conversion to git' do
    with_cvs_repository('cvs', 'simple') do |src_core|
      tmpdir do |dest_dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, branch_name: 'master', url: dest_dir)
        refute core.status.scm_dir_exist?
        core.scm.pull(src_core.scm, TestCallback.new)
        assert core.status.scm_dir_exist?
        assert core.status.exist?

        dest_commits = core.activity.commits
        src_core.activity.commits.each_with_index do |c, i|
          # Because CVS does not track authors (only committers),
          # the CVS committer becomes the Git author.
          c.committer_date.must_equal dest_commits[i].author_date
          c.committer_name.must_equal dest_commits[i].author_name

          # Depending upon version of Git used, we may or may not have a trailing \n.
          # We don't really care, so just compare the stripped versions.
          c.message.strip.must_equal dest_commits[i].message.strip
        end
      end
    end
  end

  it 'must checkout_files matching given names' do
    with_git_repository('git') do |src_core|
      dir = src_core.scm.url
      core = OhlohScm::Factory.get_core(scm_type: :git, url: dir)

      core.scm.checkout_files(['Gemfile.lock', 'package.json', 'Godeps.json', 'doesnt-exist'])

      assert system("ls #{dir}/Gemfile.lock > /dev/null")
      assert system("ls #{dir}/nested/nested_again/package.json > /dev/null")
      assert system("ls #{dir}/Godeps/Godeps.json > /dev/null")
    end
  end

  it 'must return master when branch_name is null' do
    core = OhlohScm::Factory.get_core(scm_type: :git, url: 'foobar')
    _(core.scm.branch_name_or_default).must_equal 'master'
  end
end
