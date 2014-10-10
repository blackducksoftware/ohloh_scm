require_relative '../test_helper'

module Scm::Adapters
	class CvsValidationTest < Scm::Test
		def test_rejected_urls
			[	nil, "", "foo", "http:/", "http:://", "http://", "http://a",
				":pserver", # that's not enough
				":pserver:anonymous", #still not enough
				":pserver:anonymous:@ipodder.cvs.sourceforge.net", # missing the path
				":pserver:anonymous:::@ipodder.cvs.sourceforge.net:/cvsroot/ipodder", # too many colons
				":pserver@ipodder.cvs.sourceforge.net:/cvsroot/ipodder", # not enough colons
				":pserver:anonymous:@ipodder.cvs.sourceforge.net/cvsroot/ipodder", # hostname and path not separated by colon
				":pserver:anonymous:@ipodder.cvs.source/forge.net:/cvsroot/ipodder", # slash in hostname
				":pserver:anonymous:ipodder.cvs.sourceforge.net:/cvsroot/ipodder", # missing @
				":pserver:anonymous:@ipodder.cvs.sourceforge.net:cvsroot/ipodder", # path does not begin at root
				":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsr%23oot/ipodder", # no encoded chars allowed
				":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder;asdf", # no ; in url
				":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder malicious code", # spaces not allowed
				"sourceforge.net/svn/project/trunk", # missing a protocol prefix
				"file:///home/robin/cvs", # file protocol is not allowed
				"http://svn.sourceforge.net", # http protocol is not allowed
				"git://kernel.org/whatever/linux.git", # git protocol is not allowed
				"ext@kernel.org/whatever/linux.git" # ext protocol allowed, but starts with ':'
			].each do |url|
				# Rejected for both internal and public use
				[true, false].each do |p|
					cvs = CvsAdapter.new(:url => url, :public_urls_only => p)
					assert cvs.validate_url
				end
			end
		end

		def test_accepted_urls
			[	":pserver:anonymous:@ipodder.cvs.sourceforge.net:/cvsroot/ipodder",
				":pserver:anonymous@cvs-mirror.mozilla.org:/cvsroot",
				":pserver:anonymous:@cvs-mirror.mozilla.org:/cvsroot",
				":pserver:guest:@cvs.dev.java.net:/shared/data/ccvs/repository",
				":pserver:anoncvs:password@anoncvs.postgresql.org:/projects/cvsroot",
				":pserver:anonymous:@rubyeclipse.cvs.sourceforge.net:/cvsroot/rubyeclipse",
				":pserver:cvs:cvs@cvs.winehq.org:/home/wine",
				":pserver:tcpdump:anoncvs@cvs.tcpdump.org:/tcpdump/master",
				":pserver:anonymous:@user-mode-linux.cvs.sourceforge.net:/cvsroot/user-mode-linux",
				":pserver:anonymous:@sc2.cvs.sourceforge.net:/cvsroot/sc2",
				":pserver:cool-dev:@sc2.cvs.sourceforge.net:/cvsroot/sc2", # Hyphen should be OK in username
				":pserver:cvs_anon:@cvs.scms.waikato.ac.nz:/usr/local/global-cvs/ml_cvs", # Underscores should be ok in path
				":pserver:anonymous:freefem++@idared.ann.jussieu.fr:/Users/pubcvs/cvs", # Pluses should be OK
				":ext:anoncvs@opensource.conformal.com:/anoncvs/scrotwm" # scrotwm is a real life example
			].each do |url|
				# Valid for both internal and public use
				[true, false].each do |p|
					cvs = CvsAdapter.new(:url => url, :public_urls_only => p)
					assert !cvs.validate_url
				end
			end
		end

		# Local files not accepted for public URLs
		def test_local_file_url
			cvs = CvsAdapter.new(:url => "/root")
			assert !cvs.validate_url

			cvs = CvsAdapter.new(:url => "/root", :public_urls_only => true)
			assert cvs.validate_url
		end

		def test_rejected_module_names
			[nil,"","%",";","&","\n","\t"].each do |x|
				cvs = CvsAdapter.new(:url => ":pserver:cvs:cvs@cvs.test.org:/test", :module_name => x)
				assert !cvs.valid?
				assert cvs.errors.first[0] = :module_name
			end
		end

		def test_accepted_module_names
			["myproject","my/project","my/project/2.0","my_project","0","My .Net Module", "my-module", "my-module++"].each do |x|
				cvs = CvsAdapter.new(:url => ":pserver:cvs:cvs@cvs.test.org:/test", :module_name => x)
				assert cvs.valid?
			end
		end

		def test_symlink_fixup
			cvs = CvsAdapter.new(:url => ":pserver:anoncvs:@cvs.netbeans.org:/cvs")
			assert_equal ":pserver:anoncvs:@cvs.netbeans.org:/shared/data/ccvs/repository", cvs.normalize.url

			cvs = CvsAdapter.new(:url => ":pserver:anoncvs:@cvs.netbeans.org:/cvs/")
			assert_equal ":pserver:anoncvs:@cvs.netbeans.org:/shared/data/ccvs/repository", cvs.normalize.url

			cvs = CvsAdapter.new(:url => ":pserver:anoncvs:@cvs.dev.java.net:/cvs")
			assert_equal ":pserver:anoncvs:@cvs.dev.java.net:/shared/data/ccvs/repository", cvs.normalize.url

			cvs = CvsAdapter.new(:url => ":PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/cvs")
			assert_equal ":PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/shared/data/ccvs/repository", cvs.normalize.url

			cvs = CvsAdapter.new(:url => ":pserver:anonymous:@cvs.gna.org:/cvs/eagleusb")
			assert_equal ":pserver:anonymous:@cvs.gna.org:/var/cvs/eagleusb", cvs.normalize.url
		end

		def test_sync_pserver_username_password
			# Pull username only from url
			cvs = CvsAdapter.new(:url => ":pserver:guest:@ohloh.net:/test")
			cvs.normalize
			assert_equal ':pserver:guest:@ohloh.net:/test', cvs.url
			assert_equal 'guest', cvs.username
			assert_equal '', cvs.password

			# Pull username and password from url
			cvs = CvsAdapter.new(:url => ":pserver:guest:secret@ohloh.net:/test")
			cvs.normalize
			assert_equal ':pserver:guest:secret@ohloh.net:/test', cvs.url
			assert_equal 'guest', cvs.username
			assert_equal 'secret', cvs.password

			# Apply username and password to url
			cvs = CvsAdapter.new(:url => ":pserver::@ohloh.net:/test", :username => "guest", :password => "secret")
			cvs.normalize
			assert_equal ':pserver:guest:secret@ohloh.net:/test', cvs.url
			assert_equal 'guest', cvs.username
			assert_equal 'secret', cvs.password

			# Passwords disagree, use :password attribute
			cvs = CvsAdapter.new(:url => ":pserver:guest:old@ohloh.net:/test", :username => "guest", :password => "new")
			cvs.normalize
			assert_equal ':pserver:guest:new@ohloh.net:/test', cvs.url
			assert_equal 'guest', cvs.username
			assert_equal 'new', cvs.password
		end

		def test_guess_forge
			cvs = CvsAdapter.new(:url => nil)
			assert_equal nil, cvs.guess_forge

			cvs = CvsAdapter.new(:url => "garbage_in_garbage_out")
			assert_equal nil, cvs.guess_forge

			cvs = CvsAdapter.new(:url => ':pserver:anonymous:@boost.cvs.sourceforge.net:/cvsroot/boost')
			assert_equal 'sourceforge.net', cvs.guess_forge

			cvs = CvsAdapter.new(:url => ':pserver:guest:@cvs.dev.java.net:/cvs')
			assert_equal 'java.net', cvs.guess_forge

			cvs = CvsAdapter.new(:url => ":PSERVER:ANONCVS:@CVS.DEV.JAVA.NET:/cvs")
			assert_equal 'java.net', cvs.guess_forge

			cvs = CvsAdapter.new(:url => ":pserver:guest:@colorchooser.dev.java.net:/cvs")
			assert_equal 'java.net', cvs.guess_forge
		end

		def test_validate_local_server_connection
			with_cvs_repository('cvs') do |cvs|
				assert_equal nil, cvs.validate_server_connection # No errors
			end

			cvs = CvsAdapter.new(:url => '/dev/null', :module_name => 'dummy')
			assert_not_equal nil, cvs.validate_server_connection
		end

		#remote sourceforge.net test not supporting remote ls
		#def test_validate_sourceforge_server_connection
		#	cvs = CvsAdapter.new(:url => ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle', :module_name => "contrib")
		#	assert_equal nil, cvs.validate_server_connection # No errors
		#end
	end
end
