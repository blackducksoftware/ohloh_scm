require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class DarcsValidationTest < Scm::Test
		def test_rejected_urls
			[	nil, "", "foo", "http:/", "http:://", "http://", "http://a",
				"www.selenic.com/repo/hello", # missing a protool prefix
				"http://www.selenic.com/repo/hello%20world", # no encoded strings allowed
				"http://www.selenic.com/repo/hello world", # no spaces allowed
				"git://www.selenic.com/repo/hello", # git protocol not allowed
				"svn://www.selenic.com/repo/hello" # svn protocol not allowed
			].each do |url|
				darcs = DarcsAdapter.new(:url => url, :public_urls_only => true)
				assert darcs.validate_url.any?
			end
		end

		def test_accepted_urls
			[ "http://www.selenic.com/repo/hello",
				"http://www.selenic.com:80/repo/hello",
				"https://www.selenic.com/repo/hello",
			].each do |url|
				darcs = DarcsAdapter.new(:url => url, :public_urls_only => true)
				assert !darcs.validate_url
			end
		end

		# These urls are not available to the public
		def test_rejected_public_urls
			[ "file:///home/robin/darcs",
				"/home/robin/darcs",
				"ssh://robin@localhost/home/robin/darcs",
				"ssh://localhost/home/robin/darcs"
			].each do |url|
				darcs = DarcsAdapter.new(:url => url, :public_urls_only => true)
				assert darcs.validate_url

				darcs = DarcsAdapter.new(:url => url)
				assert !darcs.validate_url
			end
		end

		def test_guess_forge
			darcs = DarcsAdapter.new(:url => nil)
			assert_equal nil, darcs.guess_forge

			darcs = DarcsAdapter.new(:url => "/home/robin/darcs")
			assert_equal nil, darcs.guess_forge

			darcs = DarcsAdapter.new( :url => 'http://www.selenic.com/repo/hello')
			assert_equal 'www.selenic.com', darcs.guess_forge

			darcs = DarcsAdapter.new( :url => 'http://algoc.darcs.sourceforge.net:8000/darcsroot/algoc')
			assert_equal 'sourceforge.net', darcs.guess_forge

			darcs = DarcsAdapter.new( :url => 'http://poliqarp.sourceforge.net/darcs/poliqarp/')
			assert_equal 'sourceforge.net', darcs.guess_forge
		end
	end
end
