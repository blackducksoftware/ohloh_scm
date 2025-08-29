# frozen_string_literal: true

module AssertScmAttrHelper
  def get_core(scm_type, opts = {})
    OhlohScm::Factory.get_core({ scm_type: scm_type, url: 'foobar' }.merge(opts))
  end

  def assert_url_error(scm_type, *urls)
    urls.each do |url|
      core = get_core(scm_type, url: url)
      refute_empty core.validation.send(:url_errors)
    end
  end

  def assert_url_valid(scm_type, url)
    core = get_core(scm_type, url: url)
    assert_nil core.validation.send(:url_errors)
  end

  def assert_branch_name_error(scm_type, *branches)
    branches.each do |branch_name|
      core = get_core(scm_type, url: ':pserver:cvs:cvs@cvs.test.org:/test', branch_name: branch_name)
      refute_empty core.validation.send(:branch_name_errors)
    end
  end

  def assert_branch_name_valid(scm_type, branch_name)
    core = get_core(scm_type, url: ':pserver:cvs:cvs@cvs.test.org:/test', branch_name: branch_name)
    assert_nil core.validation.send(:branch_name_errors)
  end
end
