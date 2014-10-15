require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Adapters
  class DarcsPatchTest < OhlohScm::Test
    def test_patch_for_commit
      with_darcs_repository('darcs') do |repo|
        commit = repo.verbose_commit('add helloworld.c')
        data = File.read(File.join(DATA_DIR, 'darcs_patch.diff'))
        assert_equal data, repo.patch_for_commit(commit)
      end
    end
  end
end
