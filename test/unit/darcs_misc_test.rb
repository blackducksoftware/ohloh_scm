require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class DarcsMiscTest < Scm::Test

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
				assert_equal ['README','makefile'], darcs.ls_tree(darcs.head_token).sort
			end
		end

		def test_export
			with_darcs_repository('darcs') do |darcs|
				Scm::ScratchDir.new do |dir|
					darcs.export(dir)
					assert_equal ['.', '..', 'README', 'makefile'], Dir.entries(dir).sort
				end
			end
		end

	end
end
