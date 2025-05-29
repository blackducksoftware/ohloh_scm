# frozen_string_literal: true

require 'spec_helper'

describe 'Factory' do
  it 'must provide access to scm, activity and status functions' do
    url = 'https://foobar.git'
    core = OhlohScm::Factory.get_core(scm_type: :git, url: url)

    assert core.status.scm.is_a?(OhlohScm::Git::Scm)
    assert_equal core.scm.url, url
    assert core.activity.method(:commits)
    assert core.status.method(:exist?)
    assert core.validation.method(:validate)
  end
end
