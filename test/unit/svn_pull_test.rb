require_relative '../test_helper'
require 'socket'

module OhlohScm::Adapters
	class SvnPullTest < OhlohScm::Test

		def test_svnadmin_create
			OhlohScm::ScratchDir.new do |dir|
				url = File.join(dir, "my_svn_repo")
				svn = SvnAdapter.new(:url => url).normalize

				assert !svn.exist?
				svn.svnadmin_create
				assert svn.exist?

				# Ensure that revision properties are settable
        # Note that only valid properties can be set
				svn.propset('log','bar')
				assert_equal 'bar', svn.propget('log')
			end
		end

		def test_basic_pull_using_svnsync
			with_svn_repository('svn') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|

					dest = SvnAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					assert_equal src.log, dest.log
				end
			end
		end

		def test_svnadmin_create_local
			OhlohScm::ScratchDir.new do |dir|
				svn = SvnAdapter.new(:url => "file://#{dir}")
				svn.svnadmin_create_local
				assert svn.exist?
				assert FileTest.exist?(File.join(dir, 'hooks', 'pre-revprop-change'))
				assert FileTest.executable?(File.join(dir, 'hooks', 'pre-revprop-change'))
				svn.run File.join(dir, 'hooks', 'pre-revprop-change')
			end
		end

		def test_svnadmin_create_remote
			OhlohScm::ScratchDir.new do |dir|
				svn = SvnAdapter.new(:url => "svn+ssh://#{Socket.gethostname}#{dir}")
				svn.svnadmin_create_remote
				assert svn.exist?
				assert FileTest.exist?(File.join(dir, 'hooks', 'pre-revprop-change'))
				assert FileTest.executable?(File.join(dir, 'hooks', 'pre-revprop-change'))
				svn.run File.join(dir, 'hooks', 'pre-revprop-change')
			end
		end
	end
end
