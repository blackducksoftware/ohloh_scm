require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Adapters
  class MtnPatchTest < Scm::Adapters::MtnAbstractTest

    def test_patch_for_commit
      init do |mtn|
        commit = mtn.verbose_commit('ad5b8a61dfb612e6c465261d6d0d31d9c061b8bf')
        data = File.read(File.join(DATA_DIR, 'mtn_diff.patch'))
        assert_equal data, mtn.patch_for_commit(commit)
      end
    end
  end
end

