require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
  class MtnPatchTest < Scm::Test

    def init
      with_mtn_repository('mtn') do |mtn|
        Scm::ScratchDir.new do |dest_dir|
          mtn.database = File.join(mtn.url, 'database.mtn')
          mtn.branch_name = 'test'
          mtn.url = File.join(mtn.url, mtn.branch_name)
          mtn.checkout_working_copy
          
          yield mtn
        end
      end
    end

    def test_patch_for_commit
      init do |mtn|
        commit = mtn.verbose_commit('ad5b8a61dfb612e6c465261d6d0d31d9c061b8bf')
        data = File.read(File.join(DATA_DIR, 'mtn_diff.patch'))
        assert_equal data, mtn.patch_for_commit(commit)
      end
    end
  end
end

