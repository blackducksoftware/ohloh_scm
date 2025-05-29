# frozen_string_literal: true

require 'spec_helper'

describe 'Bzr::Validation' do
  describe 'validate_server_connection' do
    it 'must handle non existent remote source' do
      core = OhlohScm::Factory.get_core(scm_type: :bzr, url: 'lp:foobar')
      core.validate
      refute_empty core.errors
    end
  end

  describe 'validate url' do
    it 'must have errors for invalid urls' do
      assert_url_error(:bzr, nil, '', 'foo', 'http:/', 'http:://', 'http://', 'http://a')
      assert_url_error(:bzr, 'http://www.selenic.com/repo/hello%20world') # no encoded strings allowed
      assert_url_error(:bzr, 'http://www.selenic.com/repo/hello world') # no spaces allowed
      assert_url_error(:bzr, 'git://www.selenic.com/repo/hello') # git protocol not allowed
      assert_url_error(:bzr, 'svn://www.selenic.com/repo/hello') # svn protocol not allowed
      assert_url_error(:bzr, 'lp://foobar') # lp requires no '//' after colon
      assert_url_error(:bzr, 'file:///home/test/bzr')
      assert_url_error(:bzr, '/home/test/bzr')
      assert_url_error(:bzr, 'bzr+ssh://test@localhost/home/test/bzr')
      assert_url_error(:bzr, 'bzr+ssh://localhost/home/test/bzr')
    end

    it 'wont have errors for valid urls' do
      assert_url_valid(:bzr, 'http://www.selenic.com/repo/hello')
      assert_url_valid(:bzr, 'http://www.selenic.com:80/repo/hello')
      assert_url_valid(:bzr, 'https://www.selenic.com/repo/hello')
      assert_url_valid(:bzr, 'bzr://www.selenic.com/repo/hello')
      assert_url_valid(:bzr, 'lp:foobar')
      assert_url_valid(:bzr, 'lp:~foobar/bar')
    end
  end
end
