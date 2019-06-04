require 'spec_helper'

describe 'Svn::Scm' do
  it 'must prefix file: to local path' do
    get_core(:svn, url: '').scm.send(:prefix_file_for_local_path, '').must_be_nil
    get_core(:svn, url: '/home/test').scm.send(:prefix_file_for_local_path, '/home/test')
                                     .must_equal 'file:///home/test'
  end

  it 'must require https for sourceforge' do
    OhlohScm::Svn::Scm.any_instance.stubs(:recalc_branch_name)

    url = '://svn.code.sf.net/p/gallery/code/trunk/gallery2'
    get_core(:svn, url: "http#{url}").scm.normalize.url.must_equal "https#{url}"
    get_core(:svn, url: "https#{url}").scm.normalize.url.must_equal "https#{url}"

    url = 'https://github.com/blackducksw/ohloh_scm/trunk'
    get_core(:svn, url: url).scm.normalize.url.must_equal url
  end

  it 'must recalc branch name' do
    with_svn_repository('svn') do |svn_core|
      svn_scm = get_core(:svn, url: svn_core.scm.url, branch_name: '').scm
      svn_scm.branch_name.must_be_nil
      svn_scm.send(:recalc_branch_name).must_be_empty
      svn_scm.branch_name.must_be_empty

      svn_scm = get_core(:svn, url: svn_core.scm.url, branch_name: '/').scm
      svn_scm.send(:recalc_branch_name).must_be_empty
      svn_scm.branch_name.must_be_empty

      svn_scm = get_core(:svn, url: svn_core.scm.url + '/trunk').scm
      OhlohScm::Svn::Activity.any_instance.stubs(:root).returns(svn_core.scm.url)
      svn_scm.send(:recalc_branch_name)
      svn_scm.branch_name.must_equal '/trunk'

      svn_scm = get_core(:svn, url: svn_core.scm.url + '/trunk', branch_name: nil).scm
      OhlohScm::Svn::Activity.any_instance.stubs(:root).returns(svn_core.scm.url)
      OhlohScm::Svn::Scm.any_instance.stubs(:branch_name).returns(nil)
      svn_scm.normalize.branch_name.must_be_nil
    end
  end
end
