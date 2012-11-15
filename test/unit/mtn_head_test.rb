require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Adapters
  class MtnHeadTest < Scm::Adapters::MtnAbstractTest

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
