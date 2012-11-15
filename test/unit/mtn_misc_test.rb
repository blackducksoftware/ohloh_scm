require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Adapters
  class MtnMiscTest < Scm::Adapters::MtnAbstractTest

    def test_exist
      save_mtn = nil
      init do |mtn|
        save_mtn = mtn
        assert save_mtn.exist?
      end
      assert !save_mtn.exist?
    end

    def test_ls_tree
      init do |mtn|
        assert_equal ['INSTALL', 'LICENSE', 'NEWS', 'README'], mtn.ls_tree(mtn.head_token).sort
      end
    end

    def test_export
      init do |mtn|
        Scm::ScratchDir.new do |dir|
          mtn.export(dir)
          assert_equal ['.', '..', 'INSTALL', 'LICENSE', 'NEWS', 'README'], Dir.entries(File.join(dir, mtn.branch_name)).sort
        end
      end
    end

  end
end
