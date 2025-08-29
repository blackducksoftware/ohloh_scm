require 'spec_helper'

describe 'Git::Validation' do
  it 'wont have errors for valid url' do
    core = OhlohScm::Factory.get_core(scm_type: :git, url: 'https://github.com/ruby/ruby')
    core.validation.send(:validate_attributes)
    assert_empty core.errors
  end

  it 'must have errors for invalid branch_name' do
    refute_empty get_core(:git, branch_name: 'x' * 81).validation.send(:branch_name_errors)
    refute_empty get_core(:git, branch_name: 'foo@bar').validation.send(:branch_name_errors)
  end

  it 'must have errors for invalid username' do
    refute_empty get_core(:git, username: 'x' * 33).validation.send(:username_errors)
    refute_empty get_core(:git, username: 'foo@bar').validation.send(:username_errors)
  end

  it 'must have errors for invalid password' do
    refute_empty get_core(:git, password: 'x' * 33).validation.send(:password_errors)
    refute_empty get_core(:git, password: 'escape').validation.send(:password_errors)
  end

  describe 'validate url' do
    it 'must have errors for invalid urls' do
      assert_url_error(:git, nil, '', 'foo', 'http:/', 'http:://', 'http://', 'http://a')
      assert_url_error(:git, 'kernel.org/linux/linux.git') # missing a protocol prefix
      assert_url_error(:git, 'http://kernel.org/linux/lin%32ux.git') # no encoded strings allowed
      assert_url_error(:git, 'http://kernel.org/linux/linux.git malicious code') # no spaces allowed
      assert_url_error(:git, 'svn://svn.mythtv.org/svn/trunk') # svn protocol is not allowed
      assert_url_error(:git, '/home/robin/cvs') # local file paths not allowed
      assert_url_error(:git, 'file:///home/robin/cvs') # file protocol is not allowed
      # pserver is just wrong
      assert_url_error(:git, ':pserver:anonymous:@juicereceiver.cvs.sourceforge.net:/cvsroot/juicereceiver')
    end

    it 'wont have errors for valid urls' do
      assert_url_valid(:git, 'http://kernel.org/pub/scm/git/git.git')
      assert_url_valid(:git, 'git://kernel.org/pub/scm/git/git.git')
      assert_url_valid(:git, 'https://kernel.org/pub/scm/git/git.git')
      assert_url_valid(:git, 'https://kernel.org:8080/pub/scm/git/git.git')
      assert_url_valid(:git, 'git://kernel.org/~foo/git.git')
      assert_url_valid(:git, 'http://git.onerussian.com/pub/deb/impose+.git')
      assert_url_valid(:git, 'https://Person@github.com/Person/some_repo.git')
      assert_url_valid(:git, 'http://Person@github.com/Person/some_repo.git')
      assert_url_valid(:git, 'https://github.com/Person/some_repo')
      assert_url_valid(:git, 'http://github.com/Person/some_repo')
    end
  end
end
