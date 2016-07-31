require_relative '../test_helper'

module OhlohScm::Adapters
	class HgPushTest < OhlohScm::Test

		def test_hostname
			assert !HgAdapter.new.hostname
			assert !HgAdapter.new(:url => "http://www.ohloh.net/test").hostname
			assert !HgAdapter.new(:url => "/Users/robin/foo").hostname
			assert_equal "foo", HgAdapter.new(:url => 'ssh://foo/bar').hostname
		end

		def test_local
			assert !HgAdapter.new(:url => "foo:/bar").local? # Assuming your machine is not named "foo" :-)
			assert !HgAdapter.new(:url => "http://www.ohloh.net/foo").local?
			assert !HgAdapter.new(:url => "ssh://host/Users/robin/src").local?
			assert HgAdapter.new(:url => "src").local?
			assert HgAdapter.new(:url => "/Users/robin/src").local?
			assert HgAdapter.new(:url => "file:///Users/robin/src").local?
			assert HgAdapter.new(:url => "ssh://#{Socket.gethostname}/Users/robin/src").local?
		end

		def test_path
			assert_equal nil, HgAdapter.new().path
			assert_equal nil, HgAdapter.new(:url => "http://ohloh.net/foo").path
			assert_equal nil, HgAdapter.new(:url => "https://ohloh.net/foo").path
			assert_equal "/Users/robin/foo", HgAdapter.new(:url => "file:///Users/robin/foo").path
			assert_equal "/Users/robin/foo", HgAdapter.new(:url => "ssh://localhost/Users/robin/foo").path
			assert_equal "/Users/robin/foo", HgAdapter.new(:url => "/Users/robin/foo").path
		end

		def test_hg_path
			assert_equal nil, HgAdapter.new().hg_path
			assert_equal "/Users/robin/src/.hg", HgAdapter.new(:url => "/Users/robin/src").hg_path
		end

		def test_push
			with_hg_repository('hg') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|

					dest = HgAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					src.push(dest)
					assert dest.exist?
					assert_equal src.log, dest.log

					# Commit some new code on the original and pull again
					src.run "cd '#{src.url}' && touch foo && hg add foo && hg commit -u test -m test"
					assert_equal "test\n", src.commits.last.message

					src.push(dest)
					assert_equal src.log, dest.log
				end
			end
		end

	end
end
