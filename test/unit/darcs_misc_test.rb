require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Adapters
	class DarcsMiscTest < OhlohScm::Test

		def test_exist
			save_darcs = nil
			with_darcs_repository('darcs') do |darcs|
				save_darcs = darcs
				assert save_darcs.exist?
			end
			assert !save_darcs.exist?
		end

		def test_ls_tree
			with_darcs_repository('darcs') do |darcs|
				assert_equal ['.','./helloworld.c'], darcs.ls_tree('bd7e455d648b784ce4be2db26a4e62dfe734dd66').sort
			end
		end

		def test_export
			with_darcs_repository('darcs') do |darcs|
				Scm::ScratchDir.new do |dir|
					darcs.export(dir, 'bd7e455d648b784ce4be2db26a4e62dfe734dd66')
					assert_equal ['.', '..', 'darcs.tar.gz'], Dir.entries(dir).sort
				end
			end
		end

	end
end
