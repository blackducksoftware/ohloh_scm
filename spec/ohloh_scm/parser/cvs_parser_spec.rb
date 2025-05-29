require 'spec_helper'

describe 'CvsParser' do
  describe 'parse' do
    it 'must return empty array' do
      assert_empty OhlohScm::CvsParser.parse('')
    end

    it 'must parse the log' do
      revisions = OhlohScm::CvsParser.parse File.read(FIXTURES_DIR + '/basic.rlog')

      assert_equal revisions.size, 2

      assert_equal revisions[0].token, '2005/07/25 17:09:59'
      assert_equal revisions[0].committer_name, 'pizzandre'
      assert_equal Time.utc(2005, 0o7, 25, 17, 9, 59), revisions[0].committer_date
      assert_equal revisions[0].message, '*** empty log message ***'

      assert_equal revisions[1].token, '2005/07/25 17:11:06'
      assert_equal revisions[1].committer_name, 'pizzandre'
      assert_equal Time.utc(2005, 0o7, 25, 17, 11, 6), revisions[1].committer_date
      assert_equal revisions[1].message, 'Addin UNL file with using example-'
    end

    # One file with several revisions
    it 'must test multiple revisions' do
      revisions = OhlohScm::CvsParser.parse File.read(FIXTURES_DIR + '/multiple_revisions.rlog')

      # There are 9 revisions in the rlog, but some of them are close together with the same message.
      # Therefore we bin them together into only 7 revisions.
      assert_equal revisions.size, 7

      assert_equal revisions[0].token, '2005/07/15 11:53:30'
      assert_equal revisions[0].committer_name, 'httpd'
      assert_equal revisions[0].message, 'Initial data for the intelliglue project'

      assert_equal revisions[1].token, '2005/07/15 16:40:17'
      assert_equal revisions[1].committer_name, 'pizzandre'
      assert_equal revisions[1].message, '*** empty log message ***'

      assert_equal revisions[5].token, '2005/07/26 20:35:13'
      assert_equal revisions[5].committer_name, 'pizzandre'
      assert_equal "Issue number:\nObtained from:\nSubmitted by:\nReviewed by:\nAdding current milestones-",
                   revisions[5].message

      assert_equal revisions[6].token, '2005/07/26 20:39:16'
      assert_equal revisions[6].committer_name, 'pizzandre'
      assert_equal "Issue number:\nObtained from:\nSubmitted by:\nReviewed by:\nCompleting and fixing milestones texts",
                   revisions[6].message
    end

    # A file is created and modified on the branch, then merged to the trunk, then deleted from the branch.
    # From the trunk's point of view, we should see only the merge event.
    it 'must test file created on branch as seen from trunk' do
      revisions = OhlohScm::CvsParser.parse File.read(FIXTURES_DIR + '/file_created_on_branch.rlog')
      assert_equal revisions.size, 1
      assert_equal revisions[0].message, 'merged new_file.rb from branch onto the HEAD'
    end

    # A file is created on the vender branch. This causes a simultaneous checkin on HEAD
    # with a different message ('Initial revision') but same committer_name name and timestamp.
    # We should only pick up one of these checkins.
    it 'must test simultaneous checkins' do
      revisions = OhlohScm::CvsParser.parse File.read(FIXTURES_DIR + '/simultaneous_checkins.rlog')
      assert_equal revisions.size, 1
      assert_equal revisions[0].message, 'Initial revision'
    end

    # Two different authors check in with two different messages at the exact same moment.
    # How this happens is a mystery, but I have seen it in rlogs.
    # We arbitrarily choose the first one if so.
    it 'must test simultaneous checkins_2' do
      revisions = OhlohScm::CvsParser.parse File.read(FIXTURES_DIR + '/simultaneous_checkins_2.rlog')
      assert_equal revisions.size, 1
    end
  end
end
