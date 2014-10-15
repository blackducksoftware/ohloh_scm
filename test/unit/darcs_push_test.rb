require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Adapters
	class DarcsPushTest < OhlohScm::Test

		def test_hostname
			assert !DarcsAdapter.new.hostname
			assert !DarcsAdapter.new(:url => "http://www.ohloh.net/test").hostname
			assert !DarcsAdapter.new(:url => "/Users/robin/foo").hostname
			assert_equal "foo", DarcsAdapter.new(:url => 'ssh://foo/bar').hostname
		end

		def test_local
			assert !DarcsAdapter.new(:url => "foo:/bar").local? # Assuming your machine is not named "foo" :-)
			assert !DarcsAdapter.new(:url => "http://www.ohloh.net/foo").local?
			assert !DarcsAdapter.new(:url => "ssh://host/Users/robin/src").local?
			assert DarcsAdapter.new(:url => "src").local?
			assert DarcsAdapter.new(:url => "/Users/robin/src").local?
			assert DarcsAdapter.new(:url => "file:///Users/robin/src").local?
			assert DarcsAdapter.new(:url => "ssh://#{Socket.gethostname}/Users/robin/src").local?
		end

		def test_path
			assert_equal nil, DarcsAdapter.new().path
			assert_equal nil, DarcsAdapter.new(:url => "http://ohloh.net/foo").path
			assert_equal nil, DarcsAdapter.new(:url => "https://ohloh.net/foo").path
			assert_equal "/Users/robin/foo", DarcsAdapter.new(:url => "file:///Users/robin/foo").path
			assert_equal "/Users/robin/foo", DarcsAdapter.new(:url => "ssh://localhost/Users/robin/foo").path
			assert_equal "/Users/robin/foo", DarcsAdapter.new(:url => "/Users/robin/foo").path
		end

		def test_darcs_path
			assert_equal nil, DarcsAdapter.new().darcs_path
			assert_equal "/Users/robin/src/.darcs", DarcsAdapter.new(:url => "/Users/robin/src").darcs_path
		end

		def test_push
			with_darcs_repository('darcs') do |src|
				Scm::ScratchDir.new do |dest_dir|

					dest = DarcsAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					src.push(dest)
					assert dest.exist?
					assert_equal src.log, dest.log

					# Commit some new code on the original and pull again
					src.run "cd '#{src.url}' && touch foo && darcs add foo && darcs record -a -m test"
					assert_equal "test", src.commits.last.token

					src.push(dest)
					assert_equal src.log, dest.log
				end
			end
		end

	end
end
