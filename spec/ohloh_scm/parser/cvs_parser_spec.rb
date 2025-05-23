require 'spec_helper'

describe 'CvsParser' do
  describe 'parse' do
    it 'must return empty array' do
      OhlohScm::CvsParser.parse('').must_be :empty?
    end

    it 'must parse the log' do
      revisions = OhlohScm::CvsParser.parse File.read("#{FIXTURES_DIR}/basic.rlog")

      revisions.size.must_equal 2

      revisions[0].token.must_equal '2005/07/25 17:09:59'
      revisions[0].committer_name.must_equal 'pizzandre'
      Time.utc(2005, 0o7, 25, 17, 9, 59).must_equal revisions[0].committer_date
      revisions[0].message.must_equal '*** empty log message ***'

      revisions[1].token.must_equal '2005/07/25 17:11:06'
      revisions[1].committer_name.must_equal 'pizzandre'
      Time.utc(2005, 0o7, 25, 17, 11, 6).must_equal revisions[1].committer_date
      revisions[1].message.must_equal 'Addin UNL file with using example-'
    end

    # One file with several revisions
    it 'must test multiple revisions' do
      revisions = OhlohScm::CvsParser.parse File.read("#{FIXTURES_DIR}/multiple_revisions.rlog")

      # There are 9 revisions in the rlog, but some of them are close together with the same message.
      # Therefore we bin them together into only 7 revisions.
      revisions.size.must_equal 7

      revisions[0].token.must_equal '2005/07/15 11:53:30'
      revisions[0].committer_name.must_equal 'httpd'
      revisions[0].message.must_equal 'Initial data for the intelliglue project'

      revisions[1].token.must_equal '2005/07/15 16:40:17'
      revisions[1].committer_name.must_equal 'pizzandre'
      revisions[1].message.must_equal '*** empty log message ***'

      revisions[5].token.must_equal '2005/07/26 20:35:13'
      revisions[5].committer_name.must_equal 'pizzandre'
      assert_equal "Issue number:\nObtained from:\nSubmitted by:\nReviewed by:\nAdding current milestones-",
                   revisions[5].message

      revisions[6].token.must_equal '2005/07/26 20:39:16'
      revisions[6].committer_name.must_equal 'pizzandre'
      assert_equal "Issue number:\nObtained from:\nSubmitted by:\nReviewed by:\nCompleting and fixing milestones texts",
                   revisions[6].message
    end

    # A file is created and modified on the branch, then merged to the trunk, then deleted from the branch.
    # From the trunk's point of view, we should see only the merge event.
    it 'must test file created on branch as seen from trunk' do
      revisions = OhlohScm::CvsParser.parse File.read("#{FIXTURES_DIR}/file_created_on_branch.rlog")
      revisions.size.must_equal 1
      revisions[0].message.must_equal 'merged new_file.rb from branch onto the HEAD'
    end

    # A file is created on the vender branch. This causes a simultaneous checkin on HEAD
    # with a different message ('Initial revision') but same committer_name name and timestamp.
    # We should only pick up one of these checkins.
    it 'must test simultaneous checkins' do
      revisions = OhlohScm::CvsParser.parse File.read("#{FIXTURES_DIR}/simultaneous_checkins.rlog")
      revisions.size.must_equal 1
      revisions[0].message.must_equal 'Initial revision'
    end

    # Two different authors check in with two different messages at the exact same moment.
    # How this happens is a mystery, but I have seen it in rlogs.
    # We arbitrarily choose the first one if so.
    it 'must test simultaneous checkins_2' do
      revisions = OhlohScm::CvsParser.parse File.read("#{FIXTURES_DIR}/simultaneous_checkins_2.rlog")
      revisions.size.must_equal 1
    end
  end
end
