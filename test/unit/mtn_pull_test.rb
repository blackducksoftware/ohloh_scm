require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Adapters
  class MtnPullTest < Scm::Adapters::MtnAbstractTest

    def test_pull
      with_mtn_repository('mtn') do |src|
        Scm::ScratchDir.new do |dest_dir|

          #We save the path in order to checkout a working copy later
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

          # We now checkout a working copy of the src
          # In fact, log command can't be run on a remote repository
          src.url = File.join(old_url, src.branch_name)
          src.database = File.join(old_url, 'database.mtn')
          src.checkout_working_copy

          assert_equal src.log, dest.log
        end
      end
    end

    # This test aims to sync a local copy with the repository
    # Test begins as above but we make a new change then sync
    # This test can only be run if the key dummykey has been created 
    # with an empty password
    # def test_pull_with_existing
    #   with_mtn_repository('mtn') do |src|
    #     Scm::ScratchDir.new do |dest_dir|

    #       #We save the path in order to checkout a working copy later
    #       old_url = src.url

    #       #We build a correct URL
    #       src.url = 'file://' + src.url + '/database.mtn'

    #       #And assign the branch we need
    #       src.branch_name = 'test'

    #       #We then build our new repository to clone from src
    #       dest = MtnAdapter.new(:url => File.join(dest_dir,'wc'), :database => File.join(dest_dir, 'test.mtn')).normalize
    #       dest.pull(src)

    #       # We now checkout a working copy of the src
    #       # In fact, log command can't be run on a remote repository
    #       src.url = File.join(old_url, src.branch_name)
    #       src.database = File.join(old_url, 'database.mtn')
    #       src.checkout_working_copy

    #       # We make a change on the src, commit it then sync our dest with it
    #       src.run "cd #{src.url} && echo test > dummy.txt && mtn add dummy.txt && mtn ci --author dummykey -m 'dummy commit' && mtn update"

    #       src.url = 'file://' + src.url + '/database.mtn'
    #       dest.pull(src)

    #       src.url = File.join(old_url, src.branch_name)

    #       assert_equal src.log, dest.log
    #     end
    #   end
    # end

  end
end
