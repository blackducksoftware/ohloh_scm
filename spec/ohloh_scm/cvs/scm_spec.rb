require 'spec_helper'

describe 'Cvs::Scm' do
  it 'must test symlink fixup' do
    scm = get_core(:cvs, url: ':pserver:anoncvs:@cvs.netbeans.org:/cvs').scm
    scm.normalize
    assert_equal scm.url, ':pserver:anoncvs:@cvs.netbeans.org:/shared/data/ccvs/repository'

    scm = get_core(:cvs, url: ':pserver:anoncvs:@cvs.dev.java.net:/cvs').scm
    scm.normalize
    assert_equal scm.url, ':pserver:anoncvs:@cvs.dev.java.net:/shared/data/ccvs/repository'

    scm = get_core(:cvs, url: ':PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/cvs').scm
    scm.normalize
    assert_equal scm.url, ':PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/shared/data/ccvs/repository'

    scm = get_core(:cvs, url: ':pserver:anonymous:@cvs.gna.org:/cvs/eagleusb').scm
    scm.normalize
    assert_equal scm.url, ':pserver:anonymous:@cvs.gna.org:/var/cvs/eagleusb'
  end

  it 'must test sync_pserver_username_password' do
    # Pull username only from url
    scm = get_core(:cvs, url: ':pserver:guest:@ohloh.net:/test').scm
    scm.normalize
    assert_equal scm.url, ':pserver:guest:@ohloh.net:/test'
    assert_equal scm.username, 'guest'
    assert_equal scm.password, ''

    # Pull username and password from url
    scm = get_core(:cvs, url: ':pserver:guest:secret@ohloh.net:/test').scm
    scm.normalize

    assert_equal scm.url, ':pserver:guest:secret@ohloh.net:/test'
    assert_equal scm.username, 'guest'
    assert_equal scm.password, 'secret'

    # Apply username and password to url
    scm = get_core(:cvs, url: ':pserver::@ohloh.net:/test', username: 'guest', password: 'secret').scm
    scm.normalize
    assert_equal scm.url, ':pserver:guest:secret@ohloh.net:/test'
    assert_equal scm.username, 'guest'
    assert_equal scm.password, 'secret'

    # Passwords disagree, use :password attribute
    scm = get_core(:cvs, url: ':pserver:guest:old@ohloh.net:/test', username: 'guest', password: 'new').scm
    scm.normalize
    assert_equal scm.url, ':pserver:guest:new@ohloh.net:/test'
    assert_equal scm.username, 'guest'
    assert_equal scm.password, 'new'
  end

  it 'must test guess_forge' do
    scm = get_core(:cvs, url: nil).scm
    assert_nil scm.send(:guess_forge)

    scm = get_core(:cvs, url: 'garbage_in_garbage_out').scm
    assert_nil scm.send(:guess_forge)

    scm = get_core(:cvs, url: ':pserver:anonymous:@boost.cvs.sourceforge.net:/cvsroot/boost').scm
    assert_equal scm.send(:guess_forge), 'sourceforge.net'

    scm = get_core(:cvs, url: ':pserver:guest:@cvs.dev.java.net:/cvs').scm
    assert_equal scm.send(:guess_forge), 'java.net'

    scm = get_core(:cvs, url: ':PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/cvs').scm
    assert_equal scm.send(:guess_forge), 'java.net'

    scm = get_core(:cvs, url: ':pserver:guest:@colorchooser.dev.java.net:/cvs').scm
    assert_equal scm.send(:guess_forge), 'java.net'
  end

  it 'must test local directory trim' do
    scm = get_core(:cvs, url: '/Users/robin/cvs_repo/', branch_name: 'simple').scm
    assert_equal scm.send(:trim_directory, '/Users/robin/cvs_repo/simple/foo.rb'), '/Users/robin/cvs_repo/simple/foo.rb'
  end

  it 'must test remote directory trim' do
    scm = get_core(:cvs, url: ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle',
                         branch_name: 'contrib').scm
    assert_equal scm.send(:trim_directory, '/cvsroot/moodle/contrib/foo.rb'), 'foo.rb'
  end

  it 'must test remote directory trim with port number' do
    scm = get_core(:cvs, url: ':pserver:anoncvs:anoncvs@libvirt.org:2401/data/cvs', branch_name: 'libvirt').scm
    assert_equal scm.send(:trim_directory, '/data/cvs/libvirt/docs/html/Attic'), 'docs/html/Attic'
  end

  it 'must test ordered directory list' do
    scm = get_core(:cvs, url: ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle',
                         branch_name: 'contrib').scm

    list = scm.send(:build_ordered_directory_list, ['/cvsroot/moodle/contrib/foo/bar'.intern,
                                                    '/cvsroot/moodle/contrib'.intern,
                                                    '/cvsroot/moodle/contrib/hello'.intern,
                                                    '/cvsroot/moodle/contrib/hello'.intern])
    assert_equal list.size, 4
    assert_equal list, ['', 'foo', 'hello', 'foo/bar']
  end

  it 'must test ordered directory list ignores Attic' do
    scm = get_core(:cvs, url: ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle',
                         branch_name: 'contrib').scm

    list = scm.send(:build_ordered_directory_list, ['/cvsroot/moodle/contrib/foo/bar'.intern,
                                                    '/cvsroot/moodle/contrib/Attic'.intern,
                                                    '/cvsroot/moodle/contrib/hello/Attic'.intern])

    assert_equal list.size, 4
    assert_equal list, ['', 'foo', 'hello', 'foo/bar']
  end
end
