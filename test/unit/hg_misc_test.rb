require_relative '../test_helper'

module OhlohScm::Adapters
	class HgMiscTest < OhlohScm::Test

		def test_exist
			save_hg = nil
			with_hg_repository('hg') do |hg|
				save_hg = hg
				assert save_hg.exist?
			end
			assert !save_hg.exist?
		end

		def test_ls_tree
			with_hg_repository('hg') do |hg|
				assert_equal ['README','makefile'], hg.ls_tree(hg.head_token).sort
			end
		end

		def test_export
			with_hg_repository('hg') do |hg|
				OhlohScm::ScratchDir.new do |dir|
					hg.export(dir)
					assert_equal ['.', '..', 'README', 'makefile'], Dir.entries(dir).sort
				end
			end
		end

    def test_ls_tree_encoding
      with_hg_repository('hg_with_invalid_encoding') do |hg|
        filenames = hg.ls_tree('51ea5277ca27')

        filenames.each do |filename|
          assert_equal true, filename.valid_encoding?
        end
      end
    end
	end
end
