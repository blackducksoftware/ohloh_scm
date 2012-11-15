require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Adapters
  class MtnCatFileTest < Scm::Adapters::MtnAbstractTest

    def test_cat_file
      init do |mtn|
        expected = <<-EXPECTED
Just a dummmy text
EXPECTED

        # The file was deleted in revision . Check that it does not exist now, but existed in parent.
        assert_equal nil, mtn.cat_file(Scm::Commit.new(:token => '332d55cea441deb53ec700a52b355767f72632ce'), Scm::Diff.new(:path => 'dummyText'))
        assert_equal expected, mtn.cat_file_parent(Scm::Commit.new(:token => '332d55cea441deb53ec700a52b355767f72632ce'), Scm::Diff.new(:path => 'dummyText'))
        assert_equal expected, mtn.cat_file(Scm::Commit.new(:token => 'cf43274819141164ed5da5fe9b238b38f795e903'), Scm::Diff.new(:path => 'dummyText'))
      end
    end

    # Ensure that we escape bash-significant characters like ' and & when they appear in the filename
    # def test_funny_file_name_chars
    #   Scm::ScratchDir.new do |dir|
    #     # Make a file with a problematic filename
    #     funny_name = '#|file_name` $(&\'")#'
    #     File.open(File.join(dir, funny_name), 'w') { |f| f.write "contents" }

    #     # Add it to an hg repository
    #     `cd #{dir} && hg init && hg add * && hg commit -m test`

    #     # Confirm that we can read the file back
    #     hg = HgAdapter.new(:url => dir).normalize
    #     assert_equal "contents", hg.cat_file(hg.head, Scm::Diff.new(:path => funny_name))
    #   end
    # end

  end
end
