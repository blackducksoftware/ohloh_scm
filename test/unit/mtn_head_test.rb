require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
  class MtnHeadTest < Scm::Test
    
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

    def test_head_and_parents
      init do |mtn|
        assert_equal '332d55cea441deb53ec700a52b355767f72632ce', mtn.head_token
        assert_equal '332d55cea441deb53ec700a52b355767f72632ce', mtn.head.token
        assert mtn.head.diffs.any? # diffs should be populated
        
        assert_equal 'cf43274819141164ed5da5fe9b238b38f795e903', mtn.parents(mtn.head).first.token
        assert mtn.parents(mtn.head).first.diffs.any?
      end
    end
    
  end
end
