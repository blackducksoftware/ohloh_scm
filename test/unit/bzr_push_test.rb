require_relative '../test_helper'

module OhlohScm::Adapters
	class BzrPushTest < OhlohScm::Test

		def test_hostname
			assert !BzrAdapter.new.hostname
			assert !BzrAdapter.new(:url => "http://www.ohloh.net/test").hostname
			assert !BzrAdapter.new(:url => "/Users/test/foo").hostname
			assert_equal "foo", BzrAdapter.new(:url => 'bzr+ssh://foo/bar').hostname
		end

		def test_local
			assert !BzrAdapter.new(:url => "foo:/bar").local? # Assuming your machine is not named "foo" :-)
			assert !BzrAdapter.new(:url => "http://www.ohloh.net/foo").local?
			assert !BzrAdapter.new(:url => "bzr+ssh://host/Users/test/src").local?
			assert BzrAdapter.new(:url => "src").local?
			assert BzrAdapter.new(:url => "/Users/test/src").local?
			assert BzrAdapter.new(:url => "file:///Users/test/src").local?
			assert BzrAdapter.new(:url => "bzr+ssh://#{Socket.gethostname}/Users/test/src").local?
		end

		def test_path
			assert_equal nil, BzrAdapter.new().path
			assert_equal nil, BzrAdapter.new(:url => "http://ohloh.net/foo").path
			assert_equal nil, BzrAdapter.new(:url => "https://ohloh.net/foo").path
			assert_equal "/Users/test/foo", BzrAdapter.new(:url => "file:///Users/test/foo").path
			assert_equal "/Users/test/foo", BzrAdapter.new(:url => "bzr+ssh://localhost/Users/test/foo").path
			assert_equal "/Users/test/foo", BzrAdapter.new(:url => "/Users/test/foo").path
		end

		def test_bzr_path
			assert_equal nil, BzrAdapter.new().bzr_path
			assert_equal "/Users/test/src/.bzr", BzrAdapter.new(:url => "/Users/test/src").bzr_path
		end

		def test_push
			with_bzr_repository('bzr') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|

					dest = BzrAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					src.push(dest)
					assert dest.exist?
					assert_equal src.log, dest.log

					# Commit some new code on the original and pull again
					src.run "cd '#{src.url}' && touch foo && bzr add foo && bzr whoami 'test <test@example.com>' && bzr commit -m test"
					assert_equal "test", src.commits.last.message
					assert_equal "test", src.commits.last.committer_name
					assert_equal "test@example.com", src.commits.last.committer_email

					src.push(dest)
					assert_equal src.log, dest.log
				end
			end
		end

	end
end
