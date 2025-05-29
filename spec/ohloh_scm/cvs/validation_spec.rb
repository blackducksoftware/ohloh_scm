require 'spec_helper'

describe 'Cvs::Validation' do
  describe 'validate_server_connection' do
    it 'must handle non existent remote source' do
      url = ':pserver:anonymous:@foobar.xyz_example.org:/cvsroot'
      core = OhlohScm::Factory.get_core(scm_type: :cvs, url: url, branch_name: 'foo')
      core.validate
      refute_empty core.errors
    end
  end

  it 'must have errors for invalid branch_name' do
    assert_nil get_core(:cvs, branch_name: 'x' * 81).validation.send(:branch_name_errors)
    refute_empty get_core(:cvs, branch_name: 'x' * 201).validation.send(:branch_name_errors)
    refute_empty get_core(:cvs, branch_name: 'foo@bar').validation.send(:branch_name_errors)
  end

  it 'must test rejected urls' do
    assert_url_error(:cvs, nil, '', 'foo', 'http:/', 'http:://', 'http://', 'http://a')
    assert_url_error(:cvs, ':pserver') # that's not enough
    assert_url_error(:cvs, ':pserver:anonymous') # still not enough
    assert_url_error(:cvs, ':pserver:anonymous:@ipodder.cvs.sourceforge.net') # missing the path
    assert_url_error(:cvs, ':pserver:anonymous:::@ipodder.cvs.sourceforge.net:/cvsroot/ipodder') # too many colons
    assert_url_error(:cvs, ':pserver@ipodder.cvs.sourceforge.net:/cvsroot/ipodder') # not enough colons
    # hostname and path not separated by colon
    assert_url_error(:cvs, ':pserver:anonymous:@ipodder.cvs.sourceforge.net/cvsroot/ipodder')
    assert_url_error(:cvs, ':pserver:anonymous:@ipodder.cvs.source/forge.net:/cvsroot/ipodder') # slash in hostname
    assert_url_error(:cvs, ':pserver:anonymous:ipodder.cvs.sourceforge.net:/cvsroot/ipodder') # missing @
    # path does not begin at root
    assert_url_error(:cvs, ':pserver:anonymous:@ipodder.cvs.sourceforge.net:cvsroot/ipodder')
    # no encoded chars allowed
    assert_url_error(:cvs, ':pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsr%23oot/ipodder')
    assert_url_error(:cvs, ':pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder;asdf') # no ; in url
    # spaces not allowed
    assert_url_error(:cvs, ':pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder malicious code')
    assert_url_error(:cvs, 'sourceforge.net/svn/project/trunk') # missing a protocol prefix
    assert_url_error(:cvs, 'file:///home/robin/cvs') # file protocol is not allowed
    assert_url_error(:cvs, 'http://svn.sourceforge.net') # http protocol is not allowed
    assert_url_error(:cvs, 'git://kernel.org/whatever/linux.git') # git protocol is not allowed
    assert_url_error(:cvs, 'ext@kernel.org/whatever/linux.git')
  end

  it 'must test accepted urls' do
    assert_url_valid(:cvs, ':pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder')
    assert_url_valid(:cvs, ':pserver:anonymous@cvs-mirror.mozilla.org:/cvsroot')
    assert_url_valid(:cvs, ':pserver:anonymous:@cvs-mirror.mozilla.org:/cvsroot')
    assert_url_valid(:cvs, ':pserver:guest:@cvs.dev.java.net:/shared/data/ccvs/repository')
    assert_url_valid(:cvs, ':pserver:anoncvs:password@anoncvs.postgresql.org:/projects/cvsroot')
    assert_url_valid(:cvs, ':pserver:anonymous:@rubyeclipse.cvs.sourceforge.net:/cvsroot/rubyeclipse')
    assert_url_valid(:cvs, ':pserver:cvs:cvs@cvs.winehq.org:/home/wine')
    assert_url_valid(:cvs, ':pserver:tcpdump:anoncvs@cvs.tcpdump.org:/tcpdump/master')
    assert_url_valid(:cvs, ':pserver:anonymous:@user-mode-linux.cvs.sourceforge.net:/cvsroot/user-mode-linux')
    assert_url_valid(:cvs, ':pserver:anonymous:@sc2.cvs.sourceforge.net:/cvsroot/sc2')
    # Hyphen should be OK in username
    assert_url_valid(:cvs, ':pserver:cool-dev:@sc2.cvs.sourceforge.net:/cvsroot/sc2')
    # Underscores should be ok in path
    assert_url_valid(:cvs, ':pserver:cvs_anon:@cvs.scms.waikato.ac.nz:/usr/local/global-cvs/ml_cvs')
    # Pluses should be OK
    assert_url_valid(:cvs, ':pserver:anonymous:freefem++@idared.ann.jussieu.fr:/Users/pubcvs/cvs')
    assert_url_valid(:cvs, ':ext:anoncvs@opensource.conformal.com:/anoncvs/scrotwm')
  end

  it 'must test rejected branch_names' do
    assert_branch_name_error(:cvs, nil, '', '%', ';', '&', "\n", "\t")
  end

  it 'must test accepted branch_names' do
    assert_branch_name_valid(:cvs, 'myproject')
    assert_branch_name_valid(:cvs, 'my/project')
    assert_branch_name_valid(:cvs, 'my/project/2.0')
    assert_branch_name_valid(:cvs, 'my_project')
    assert_branch_name_valid(:cvs, '0')
    assert_branch_name_valid(:cvs, 'My .Net Module')
    assert_branch_name_valid(:cvs, 'my-module')
    assert_branch_name_valid(:cvs, 'my-module++')
  end
end
