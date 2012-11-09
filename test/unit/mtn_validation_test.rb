require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Adapters
  class MtnValidationTest < Scm::Adapters::MtnAbstractTest

    def test_url_splitting
      mtn = MtnAdapter.new(:url => 'file:///tmp/test.mtn?testBranch')
      assert_equal 'testBranch', mtn.branch_name
      assert_equal 'file:///tmp/test.mtn', mtn.url

      mtn = MtnAdapter.new(:url => '/tmp/test/')
      assert_equal '/tmp/test/', mtn.url
      assert_equal nil, mtn.branch_name

    end

    def test_branch_name_detection
      # Let's build a working copy by pulling to test branch name retrieval
      init do |mtn|
        #First erase the content of branch_name
        expected_branch_name = mtn.branch_name
        mtn.branch_name = ''
        
        # try to get it
        assert_equal expected_branch_name, mtn.branch_name
      end
    end

    def test_database_detection
      init do |mtn|
        #erase the information
        expected_database = mtn.database
        mtn.database = ''
        
        assert_equal expected_database, mtn.database
      end
    end

  end
end
