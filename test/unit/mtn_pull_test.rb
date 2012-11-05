require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
  class MtnPullTest < Scm::Test

    def test_pull
      with_mtn_repository('mtn') do |src|
        Scm::ScratchDir.new do |dest_dir|

          #We save the path in order to point to the working copy
          old_url = src.url

          #We build a correct URL
          src.url = 'file://' + src.url + '/database.mtn'

          #And assign the branch we need
          src.branch_name = 'test'

          #We then build our new repository to clone from src
          dest = MtnAdapter.new(:url => File.join(dest_dir,'wc'), :database => File.join(dest_dir, 'test.mtn')).normalize
          assert !dest.exist?

          dest.pull(src)
          assert dest.exist?

          # We now use the working copy of the src, so we change the attributes
          # In fact, log command can't be run on a remote repository
          src.url = File.join(old_url, src.branch_name)

          assert_equal src.log, dest.log
        end
      end
    end

  end
end
