# encoding: utf-8
require File.dirname(__FILE__) + '/../test_helper'

module Scm::Adapters
	class BzrMiscTest < Scm::Test

		def test_exist
			save_bzr = nil
			with_bzr_repository('bzr') do |bzr|
				save_bzr = bzr
				assert save_bzr.exist?
			end
			assert !save_bzr.exist?
		end

		def test_ls_tree
			with_bzr_repository('bzr') do |bzr|
				assert_equal ['Cédric.txt',
                'file1.txt',
					      'file3.txt',
					      'file4.txt',
					      'file5.txt'],
					     bzr.ls_tree(bzr.head_token).sort
			end
		end

		def test_export
			with_bzr_repository('bzr') do |bzr|
				Scm::ScratchDir.new do |dir|
					bzr.export(dir)
					assert_equal ['.', '..', 'Cédric.txt', 'file1.txt', 'file3.txt', 'file4.txt', 'file5.txt'], Dir.entries(dir).sort
				end
			end
		end

	end
end
