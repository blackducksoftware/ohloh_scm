require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
  class MtnCommitsTest < Scm::Test

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

    def test_commit_count
      init do |mtn|
        assert_equal 5, mtn.commit_count
        assert_equal 4, mtn.commit_count(:after => 'baddca99ba8586af4104d6b178291621278bbf88')
        assert_equal 0, mtn.commit_count(:after => '332d55cea441deb53ec700a52b355767f72632ce')
      end
    end

    def test_commit_tokens
      init do |mtn|
        assert_equal ['332d55cea441deb53ec700a52b355767f72632ce',
                      'cf43274819141164ed5da5fe9b238b38f795e903',
                      'ad5b8a61dfb612e6c465261d6d0d31d9c061b8bf',
                      'ced0b8c900531859b64eb632549666a38c89d7a0',
                      'baddca99ba8586af4104d6b178291621278bbf88'], mtn.commit_tokens
        
        assert_equal ['332d55cea441deb53ec700a52b355767f72632ce'],
        mtn.commit_tokens(:after => 'cf43274819141164ed5da5fe9b238b38f795e903')

        assert_equal [], mtn.commit_tokens(:after => '332d55cea441deb53ec700a52b355767f72632ce')
      end
    end

    def test_commits
      init do |mtn|
        assert_equal ['332d55cea441deb53ec700a52b355767f72632ce',
                      'cf43274819141164ed5da5fe9b238b38f795e903',
                      'ad5b8a61dfb612e6c465261d6d0d31d9c061b8bf',
                      'ced0b8c900531859b64eb632549666a38c89d7a0',
                      'baddca99ba8586af4104d6b178291621278bbf88'], mtn.commits.collect { |c| c.token }
        
        assert_equal ['332d55cea441deb53ec700a52b355767f72632ce',
                      'cf43274819141164ed5da5fe9b238b38f795e903',
                      'ad5b8a61dfb612e6c465261d6d0d31d9c061b8bf'],
        mtn.commits(:after => 'ced0b8c900531859b64eb632549666a38c89d7a0').collect { |c| c.token }
        
        # Check that the diffs are not populated
        assert_equal [], mtn.commits(:after => 'ced0b8c900531859b64eb632549666a38c89d7a0').first.diffs
        
        assert_equal [], mtn.commits(:after => '332d55cea441deb53ec700a52b355767f72632ce')
      end
    end

    # def test_trunk_only_commits
    # 	with_mtn_repository('mtn_dupe_delete') do |mtn|
    # 		assert_equal ['73e93f57224e3fd828cf014644db8eec5013cd6b',
    # 									'732345b1d5f4076498132fd4b965b1fec0108a50',
    # 									# '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
    # 									'72fe74d643bdcb30b00da3b58796c50f221017d0'],
    # 			mtn.commits(:trunk_only => true).collect { |c| c.token }
    # 	end
    # end

    # def test_trunk_only_commit_count
    # 	with_mtn_repository('mtn_dupe_delete') do |mtn|
    # 		assert_equal 4, mtn.commit_count(:trunk_only => false)
    # 		assert_equal 3, mtn.commit_count(:trunk_only => true)
    # 	end
    # end

    # def test_trunk_only_commit_tokens
    # 	with_mtn_repository('mtn_dupe_delete') do |mtn|
    # 		assert_equal ['73e93f57224e3fd828cf014644db8eec5013cd6b',
    # 									'732345b1d5f4076498132fd4b965b1fec0108a50',
    # 									'525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
    # 									'72fe74d643bdcb30b00da3b58796c50f221017d0'],
    # 			mtn.commit_tokens(:trunk_only => false)

    # 		assert_equal ['73e93f57224e3fd828cf014644db8eec5013cd6b',
    # 									'732345b1d5f4076498132fd4b965b1fec0108a50',
    # 									# '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
    # 									'72fe74d643bdcb30b00da3b58796c50f221017d0'],
    # 			mtn.commit_tokens(:trunk_only => true)
    # 	end
    # end

    # def test_trunk_only_commit_tokens_using_after
    # 	with_mtn_repository('mtn_dupe_delete') do |mtn|
    # 		assert_equal ['732345b1d5f4076498132fd4b965b1fec0108a50',
    # 									'525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
    # 									'72fe74d643bdcb30b00da3b58796c50f221017d0'],
    # 			mtn.commit_tokens(
    # 				:after => '73e93f57224e3fd828cf014644db8eec5013cd6b',
    # 				:trunk_only => false)

    # 		assert_equal ['732345b1d5f4076498132fd4b965b1fec0108a50',
    # 									# '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
    # 									'72fe74d643bdcb30b00da3b58796c50f221017d0'],
    # 			mtn.commit_tokens(
    # 				:after => '73e93f57224e3fd828cf014644db8eec5013cd6b',
    # 				:trunk_only => true)

    # 		assert_equal [], mtn.commit_tokens(
    # 			:after => '72fe74d643bdcb30b00da3b58796c50f221017d0',
    # 			:trunk_only => true)
    # 	end
    # end

    # def test_trunk_only_commits
    # 	with_mtn_repository('mtn_dupe_delete') do |mtn|
    # 		assert_equal ['73e93f57224e3fd828cf014644db8eec5013cd6b',
    # 									'732345b1d5f4076498132fd4b965b1fec0108a50',
    # 									# '525de321d8085bc1d4a3c7608fda6b4020027985', # On branch
    # 									'72fe74d643bdcb30b00da3b58796c50f221017d0'],
    # 			mtn.commits(:trunk_only => true).collect { |c| c.token }
    # 	end
    # end

    def test_each_commit
      commits = []
      init do |mtn|
        mtn.each_commit do |c|
          assert c.token.length == 40
          assert c.author_name
          assert c.author_date.is_a?(Time)
          assert c.message.length > 0
          assert c.diffs.any?
          # Check that the diffs are populated
          c.diffs.each do |d|
            assert d.action =~ /^[MAD]$/
            assert d.path.length > 0
          end
          commits << c
        end
        assert !FileTest.exist?(mtn.log_filename) # Make sure we cleaned up after ourselves
        
        # Verify that we got the commits in forward chronological order
        assert_equal ['332d55cea441deb53ec700a52b355767f72632ce',
                      'cf43274819141164ed5da5fe9b238b38f795e903',
                      'ad5b8a61dfb612e6c465261d6d0d31d9c061b8bf',
                      'ced0b8c900531859b64eb632549666a38c89d7a0',
                      'baddca99ba8586af4104d6b178291621278bbf88'], commits.collect { |c| c.token }
      end
    end
    
    def test_each_commit_after
      commits = []
      init do |mtn|
        mtn.each_commit(:after => 'ad5b8a61dfb612e6c465261d6d0d31d9c061b8bf') do |c|
          commits << c
        end
        assert_equal ['332d55cea441deb53ec700a52b355767f72632ce',
                      'cf43274819141164ed5da5fe9b238b38f795e903'], commits.collect { |c| c.token }
      end
    end
  end
end

