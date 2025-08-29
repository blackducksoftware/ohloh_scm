# frozen_string_literal: true

require 'spec_helper'

describe 'Version' do
  it 'must return the version string' do
    assert OhlohScm::Version::STRING.is_a?(String)
  end
end
