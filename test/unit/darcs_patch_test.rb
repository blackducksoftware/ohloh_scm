require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
  class DarcsPatchTest < Scm::Test
    def test_patch_for_commit
      with_darcs_repository('darcs') do |repo|
        commit = repo.verbose_commit(1)
        data = File.read(File.join(DATA_DIR, 'darcs_patch.diff'))
        assert_equal data, repo.patch_for_commit(commit)
      end
    end
  end
end
