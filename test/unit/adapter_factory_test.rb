require_relative '../test_helper'

module OhlohScm::Adapters
	class FactoryTest < OhlohScm::Test

		def test_factory_darcs
			Scm::ScratchDir.new do |path|
				`cd #{path} && darcs init`
				darcs = Factory.from_path(path)
				assert darcs.is_a?(DarcsAdapter)
				assert_equal darcs.url, path
			end
		end

		def test_factory_hg
			OhlohScm::ScratchDir.new do |path|
				`cd #{path} && hg init`
				hg = Factory.from_path(path)
				assert hg.is_a?(HgAdapter)
				assert_equal hg.url, path
			end
		end

		def test_factory_bzr
			OhlohScm::ScratchDir.new do |path|
				`cd #{path} && bzr init`
				bzr = Factory.from_path(path)
				assert bzr.is_a?(BzrAdapter)
				assert_equal bzr.url, path
			end
		end

		def test_factory_git
			OhlohScm::ScratchDir.new do |path|
				`cd #{path} && git init`
				git = Factory.from_path(path)
				assert git.is_a?(GitAdapter)
				assert_equal git.url, path
			end
		end

		def test_factory_svn
			OhlohScm::ScratchDir.new do |path|
				`cd #{path} && svnadmin create foo`
				svn = Factory.from_path(File.join(path, 'foo'))
				assert svn.is_a?(SvnAdapter)
				assert_equal svn.url, 'file://' + File.expand_path(File.join(path, 'foo'))
			end
		end

		def test_factory_svn_checkout
			OhlohScm::ScratchDir.new do |path|
				`cd #{path} && svnadmin create foo`
				`cd #{path} && svn co file://#{File.expand_path(File.join(path, 'foo'))} bar`
				svn = Factory.from_path(File.join(path, 'bar'))
				assert svn.is_a?(SvnAdapter)
				# Note that even though we gave checkout dir 'bar' to the factory,
				# we get back a link to the original repo at 'foo'
				assert_equal svn.url, 'file://' + File.expand_path(File.join(path, 'foo'))
			end
		end

		def test_factory_from_cvs_checkout
			with_cvs_repository('cvs', 'simple') do |cvs|
				OhlohScm::ScratchDir.new do |path|
					`cd #{path} && cvsnt -d #{File.expand_path(cvs.url)} co simple 2> /dev/null`
					factory_response = Factory.from_path(File.join(path, 'simple'))
					assert factory_response.is_a?(CvsAdapter)
					assert_equal cvs.url, factory_response.url
				end
			end
		end

	end
end

