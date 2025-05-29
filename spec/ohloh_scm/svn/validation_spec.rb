require 'spec_helper'

describe 'Svn::Status' do
  it 'should validate usernames' do
    [nil, '', 'joe_36', 'a' * 32, 'robin@ohloh.net'].each do |username|
      assert !get_core(:svn, username: username).validation.send(:username_errors)
    end
  end

  it 'should validate rejected urls' do
    [nil, '', 'foo', 'http:/', 'http:://', 'http://',
     'sourceforge.net/svn/project/trunk', # missing a protocol prefix
     'http://robin@svn.sourceforge.net/', # must not include a username with the url
     '/home/robin/cvs', # local file paths not allowed
     'git://kernel.org/whatever/linux.git', # git protocol is not allowed
     ':pserver:anonymous:@juicereceiver.cvs.sourceforge.net:/cvsroot/juicereceiver', # pserver is just wrong
     'svn://svn.gajim.org:/gajim/trunk', # invalid port number
     'svn://svn.gajim.org:abc/gajim/trunk', # invalid port number
     'svn log https://svn.sourceforge.net/svnroot/myserver/trunk'].each do |url|
      # Rejected for both internal and public use
      assert get_core(:svn, url: url).validation.send(:url_errors)
    end
  end

  it 'should validate urls' do
    [
      'https://svn.sourceforge.net/svnroot/opende/trunk', # https protocol OK
      'svn://svn.gajim.org/gajim/trunk', # svn protocol OK
      'http://svn.mythtv.org/svn/trunk/mythtv', # http protocol OK
      'https://svn.sourceforge.net/svnroot/vienna-rss/trunk/2.0.0', # periods, numbers and dashes OK
      'svn://svn.gajim.org:3690/gajim/trunk', # port number OK
      'http://svn.mythtv.org:80/svn/trunk/mythtv', # port number OK
      'http://svn.gnome.org/svn/gtk+/trunk', # + character OK
      'http://svn.gnome.org', # no path, no trailing /, just a domain name is OK
      'http://brlcad.svn.sourceforge.net/svnroot/brlcad/rt^3/trunk', # a caret ^ is allowed
      'http://www.thus.ch/~patrick/svn/pvalsecc', # ~ is allowed
      'http://franklinmath.googlecode.com/svn/trunk/Franklin Math' # space is allowed in path
    ].each do |url|
      # Accepted for both internal and public use
      assert !get_core(:svn, url: url).validation.send(:url_errors)
    end
  end

  # These urls are not available to the public
  it 'should reject public urls' do
    ['file:///home/robin/svn'].each do |url|
      assert get_core(:svn, url: url).validation.send(:url_errors)
    end
  end

  it 'should validate_server_connection' do
    with_svn_repository('svn') do |svn|
      svn.validation.send(:validate_server_connection)
      assert_empty svn.validation.errors
    end
  end

  it 'should strip trailing whitespace in branch_name' do
    assert_equal get_core(:svn, branch_name: '/trunk/').scm.normalize.branch_name, '/trunk'
  end

  it 'should catch exception when validating server connection' do
    git_svn = get_core(:svn)
    git_svn.validation.instance_variable_set('@errors', nil)
    git_svn.validation.send :validate_server_connection
    msg = 'An error occured connecting to the server. Check the URL, username, and password.'
    assert_equal git_svn.validation.errors, [[:failed, msg]]
  end

  it 'should validate head token when validating server connection' do
    git_svn = get_core(:svn)
    git_svn.validation.instance_variable_set('@errors', nil)
    OhlohScm::Svn::Activity.any_instance.stubs(:head_token).returns(nil)
    git_svn.validation.expects(:url_error)
    git_svn.validation.send :validate_server_connection
    msg = "The server did not respond to a 'svn info' command. Is the URL correct?"
    assert_equal git_svn.validation.errors, [[:failed, msg]]
  end

  it 'should validate url when validating server connection' do
    git_svn = get_core(:svn)
    git_svn.validation.instance_variable_set('@errors', nil)
    OhlohScm::Svn::Activity.any_instance.stubs(:head_token).returns('')
    OhlohScm::Svn::Activity.any_instance.stubs(:root).returns('tt')
    git_svn.validation.send :validate_server_connection
    assert_equal git_svn.validation.errors, 
    [[:failed, 'The URL did not match the Subversion root tt. Is the URL correct?']]
  end
end
