require_relative '../test_helper'

module OhlohScm::Parsers
	class SvnChainTest < OhlohScm::Test

		def test_chain
			with_svn_chain_repository('svn_with_branching', '/trunk') do |svn|
				chain = svn.chain
				assert_equal 4, chain.size

				# In revision 1, the trunk is created.
				assert_equal '/trunk', chain[0].branch_name
				assert_equal 1, chain[0].first_token
				assert_equal 2, chain[0].final_token

				# In revision 3, the trunk was deleted, but restored in revision 4.
				# This creates the first discontinuity, and the first link in the chain.
				assert_equal '/trunk', chain[1].branch_name
				assert_equal 4, chain[1].first_token
				assert_equal 4, chain[1].final_token

				# In revision 5, the branch is created by copying the trunk from revision 4.
				assert_equal '/branches/development', chain[2].branch_name
				assert_equal 5, chain[2].first_token
				assert_equal 7, chain[2].final_token

				# In revision 8, a new trunk is created by copying the branch.
				# This trunk still lives on, so its final_token is nil.
				assert_equal '/trunk', chain[3].branch_name
				assert_equal 8, chain[3].first_token
				assert_equal nil, chain[3].final_token
			end
		end

		def test_parent_svn
			with_svn_chain_repository('svn_with_branching', '/trunk') do |svn|
				# In this repository, /branches/development becomes
				# the /trunk in revision 8. So there should be a parent
				# will final_token 7.
				p1 = svn.parent_svn
				assert_equal p1.url, svn.root + '/branches/development'
				assert_equal p1.branch_name, '/branches/development'
				assert_equal p1.final_token, 7

				# There's another move at revision 5, in which /branch/development
				# is created by copying /trunk from revision 4.
				p2 = p1.parent_svn
				assert_equal p2.url, svn.root + '/trunk'
				assert_equal p2.branch_name, '/trunk'
				assert_equal p2.final_token, 4
			end
		end

		def test_parent_branch_name
			svn = OhlohScm::Adapters::SvnChainAdapter.new(:branch_name => "/trunk")

			assert_equal "/branches/b", svn.parent_branch_name(OhlohScm::Diff.new(:action => 'A',
					:path => "/trunk", :from_revision => 1, :from_path => "/branches/b"))
		end

    def test_next_revision_xml_valid_encoding
      with_invalid_encoded_svn_repository do |svn|
        assert_equal true, svn.next_revision_xml(0).valid_encoding?
      end
    end
	end
end
