require 'spec_helper'

describe 'Svn::Scm' do
  it 'must prefix file: to local path' do
    assert_nil get_core(:svn, url: '').scm.send(:prefix_file_for_local_path, '')
    assert_equal get_core(:svn, url: '/home/test').scm.send(:prefix_file_for_local_path, '/home/test'),
                 'file:///home/test'
  end

  it 'must require https for sourceforge' do
    OhlohScm::Svn::Scm.any_instance.stubs(:recalc_branch_name)

    url = '://svn.code.sf.net/p/gallery/code/trunk/gallery2'
    assert_equal get_core(:svn, url: "http#{url}").scm.normalize.url, "https#{url}"
    assert_equal get_core(:svn, url: "https#{url}").scm.normalize.url, "https#{url}"

    url = 'https://github.com/blackducksw/ohloh_scm/trunk'
    assert_equal get_core(:svn, url: url).scm.normalize.url, url
  end

  it 'must recalc branch name' do
    with_svn_repository('svn') do |svn_core|
      svn_scm = get_core(:svn, url: svn_core.scm.url, branch_name: '').scm
      assert_nil svn_scm.branch_name
      assert_empty svn_scm.send(:recalc_branch_name)
      assert_empty svn_scm.branch_name

      svn_scm = get_core(:svn, url: svn_core.scm.url, branch_name: '/').scm
      assert_empty svn_scm.send(:recalc_branch_name)
      assert_empty svn_scm.branch_name

      svn_scm = get_core(:svn, url: "#{svn_core.scm.url}/trunk").scm
      OhlohScm::Svn::Activity.any_instance.stubs(:root).returns(svn_core.scm.url)
      svn_scm.send(:recalc_branch_name)
      assert_equal svn_scm.branch_name, '/trunk'

      svn_scm = get_core(:svn, url: "#{svn_core.scm.url}/trunk", branch_name: nil).scm
      OhlohScm::Svn::Activity.any_instance.stubs(:root).returns(svn_core.scm.url)
      assert_equal svn_scm.normalize.branch_name, '/trunk'
    end
  end

  describe 'restrict_url_to_trunk' do
    it 'must return url when url ends with trunk' do
      svn_scm = get_core(:svn, url: 'svn:foobar/trunk').scm
      assert_equal svn_scm.restrict_url_to_trunk, svn_scm.url
    end

    it 'must append trunk to url and set branch_name when trunk folder is present' do
      with_svn_repository('svn') do |svn_core|
        scm = svn_core.scm
        assert_equal scm.url, svn_core.activity.root
        assert_nil scm.branch_name

        scm.restrict_url_to_trunk

        assert_equal scm.url, "#{svn_core.activity.root}/trunk"
        assert_equal scm.branch_name, '/trunk'
      end
    end

    it 'must update url and branch_name when repo has a single subfolder' do
      with_svn_repository('svn_subdir') do |svn_core|
        scm = svn_core.scm
        assert_equal scm.url, svn_core.activity.root
        assert_nil scm.branch_name

        scm.restrict_url_to_trunk

        assert_equal scm.url, "#{svn_core.activity.root}/subdir/trunk"
        assert_equal scm.branch_name, '/subdir/trunk'
      end
    end
  end
end
