require_relative '../test_helper'

module OhlohScm::Adapters
	class SvnCommitsTest < OhlohScm::Test

		def test_commits
			with_svn_repository('svn') do |svn|
				assert_equal 5, svn.commit_count
				assert_equal 3, svn.commit_count(:after => 2)
				assert_equal 0, svn.commit_count(:after => 1000)

				assert_equal [1,2,3,4,5], svn.commit_tokens
				assert_equal [3,4,5], svn.commit_tokens(:after => 2)
				assert_equal [], svn.commit_tokens(:after => 1000)

				assert_equal [1,2,3,4,5], svn.commits.collect { |c| c.token }
				assert_equal [3,4,5], svn.commits(:after => 2).collect { |c| c.token }
				assert_equal [], svn.commits(:after => 1000)
				assert !FileTest.exist?(svn.log_filename)
			end
		end

		# Confirms that the sha1 matches those created by git exactly
		def test_sha1
			with_svn_repository('svn') do |svn|
				assert_equal '0000000000000000000000000000000000000000', svn.compute_sha1(nil)
				assert_equal '0000000000000000000000000000000000000000', svn.compute_sha1('')
				assert_equal '30d74d258442c7c65512eafab474568dd706c430', svn.compute_sha1('test')
			end
		end

		# Given a commit with diffs, fill in all of the SHA1 values.
		def test_populate_sha1
			with_svn_repository('svn') do |svn|
				c = OhlohScm::Commit.new(:token => 3)
				c.diffs = [OhlohScm::Diff.new(:path => "/trunk/helloworld.c", :action => "M")]
				svn.populate_commit_sha1s!(c)
				assert_equal 'f6adcae4447809b651c787c078d255b2b4e963c5', c.diffs.first.sha1
				assert_equal '4c734ad53b272c9b3d719f214372ac497ff6c068', c.diffs.first.parent_sha1
			end
		end

		def test_strip_commit_branch
			svn = SvnAdapter.new(:branch_name => "/trunk")
			commit = OhlohScm::Commit.new

			# nil diffs before => nil diffs after
			assert !svn.strip_commit_branch(commit).diffs

			# [] diffs before => [] diffs after
			commit.diffs = []
			assert_equal [], svn.strip_commit_branch(commit).diffs

			commit.diffs = [
				OhlohScm::Diff.new(:path => "/trunk"),
				OhlohScm::Diff.new(:path => "/trunk/helloworld.c"),
				OhlohScm::Diff.new(:path => "/branches/a")
			]
			assert_equal ['', '/helloworld.c'], svn.strip_commit_branch(commit).diffs.collect { |d| d.path }.sort
		end

		def test_strip_diff_branch
			svn = SvnAdapter.new(:branch_name => "/trunk")
			assert !svn.strip_diff_branch(OhlohScm::Diff.new)
			assert !svn.strip_diff_branch(OhlohScm::Diff.new(:path => "/branches/b"))
			assert_equal '', svn.strip_diff_branch(OhlohScm::Diff.new(:path => "/trunk")).path
			assert_equal '/helloworld.c', svn.strip_diff_branch(OhlohScm::Diff.new(:path => "/trunk/helloworld.c")).path
		end

		def test_strip_path_branch
			# Returns nil for any path outside of SvnAdapter::branch_name
			assert !SvnAdapter.new.strip_path_branch(nil)
			assert !SvnAdapter.new(:branch_name => "/trunk").strip_path_branch("/branches/foo")
			assert !SvnAdapter.new(:branch_name => "/trunk").strip_path_branch("/t")

			# If branch_name is empty or root, returns path unchanged
			assert_equal '', SvnAdapter.new.strip_path_branch('')
			assert_equal '/trunk', SvnAdapter.new.strip_path_branch('/trunk')

			# If path is equal to or is a subdirectory of branch_name, returns subdirectory portion only.
			assert_equal '', SvnAdapter.new(:branch_name => "/trunk").strip_path_branch('/trunk')
			assert_equal '/foo', SvnAdapter.new(:branch_name => "/trunk").strip_path_branch('/trunk/foo')
		end

		def test_strip_path_branch_with_special_chars
			assert_equal '/foo', SvnAdapter.new(:branch_name => '/trunk/hamcrest-c++').strip_path_branch('/trunk/hamcrest-c++/foo')
		end

		def test_remove_dupes_add_modify
			svn = SvnAdapter.new
			c = OhlohScm::Commit.new(:diffs => [ OhlohScm::Diff.new(:action => "A", :path => "foo"),
																			OhlohScm::Diff.new(:action => "M", :path => "foo") ])

			svn.remove_dupes(c)
			assert_equal 1, c.diffs.size
			assert_equal 'A', c.diffs.first.action
		end

		def test_remove_dupes_add_replace
			svn = SvnAdapter.new
			c = OhlohScm::Commit.new(:diffs => [ OhlohScm::Diff.new(:action => "R", :path => "foo"),
																			OhlohScm::Diff.new(:action => "A", :path => "foo") ])

			svn.remove_dupes(c)
			assert_equal 1, c.diffs.size
			assert_equal 'A', c.diffs.first.action
		end

        def test_remove_dupes_with_sql_acii_encoding
           #Note: If there are two files that are identical except for the encoding, ohloh_scm should only keep one.
           svn = SvnAdapter.new
           diff_1 = OhlohScm::Diff.new(:action => "M", :path => "/FritzBoxDial/FritzBoxDial/formWählbox.vb")
           diff_2 = OhlohScm::Diff.new(:action => "A", :path => "/FritzBoxDial/FritzBoxDial/formWählbox.vb")
		   c = OhlohScm::Commit.new(:diffs => [diff_1 ,diff_2])
																			
           svn.remove_dupes(c)
           puts c.diffs.count
           assert_equal 1, c.diffs.size
           assert_equal 'A', c.diffs.first.action
        end

		# Had so many bugs around this case that a test was required
		def test_deepen_commit_with_nil_diffs
			with_svn_repository('svn') do |svn|
				c = svn.commits.first # Doesn't matter which
				c.diffs = nil
				svn.populate_commit_sha1s!(svn.deepen_commit(c)) # If we don't crash we pass the test.
			end
		end

		def test_deep_commits
			with_svn_repository('deep_svn') do |svn|

				# The full repository contains 4 revisions...
				assert_equal 4, svn.commit_count

				# ...however, the current trunk contains only revisions 3 and 4.
				# That's because the branch was moved to replace the trunk at revision 3.
				#
				# Even though there was a different trunk directory present in
				# revisions 1 and 2, it is not visible to Ohloh.

				trunk = SvnAdapter.new(:url => File.join(svn.url,'trunk'), :branch_name => '/trunk').normalize
				assert_equal 2, trunk.commit_count
				assert_equal [3,4], trunk.commit_tokens


				deep_commits = []
				trunk.each_commit { |c| deep_commits << c }

				# When the branch is moved to replace the trunk in revision 3,
				# the Subversion log shows
				#
				#   D /branches/b
				#   A /trunk (from /branches/b:2)
				#
				# However, there are files in those directories. Make sure the commits
				# that we generate include all of those files not shown by the log.
				#
				# Also, our commits do not include diffs for the actual directories;
				# only the files within those directories.
				#
				# Also, after we are only tracking the /trunk and not /branches/b, then
				# there should not be anything referring to activity in /branches/b.

				assert_equal 3, deep_commits.first.token # Make sure this is the right revision
				assert_equal 2, deep_commits.first.diffs.size # Two files seen

				assert_equal 'A', deep_commits.first.diffs[0].action
				assert_equal '/subdir/bar.rb', deep_commits.first.diffs[0].path
				assert_equal 'A', deep_commits.first.diffs[1].action
				assert_equal '/subdir/foo.rb', deep_commits.first.diffs[1].path

				# In Revision 4, a directory is renamed. This shows in the Subversion log as
				#
				#   A /trunk/newdir (from /trunk/subdir:3)
				#   D /trunk/subdir
				#
				# Again, there are files in this directory, so make sure our commit includes
				# both delete and add events for all of the files in this directory, but does
				# not actually refer to the directories themselves.

				assert_equal 4, deep_commits.last.token # Make sure we're checking the right revision

				# There should be 2 files removed and two files added
				assert_equal 4, deep_commits.last.diffs.size

				assert_equal 'A', deep_commits.last.diffs[0].action
				assert_equal '/newdir/bar.rb', deep_commits.last.diffs[0].path
				assert_equal 'A', deep_commits.last.diffs[1].action
				assert_equal '/newdir/foo.rb', deep_commits.last.diffs[1].path

				assert_equal 'D', deep_commits.last.diffs[2].action
				assert_equal '/subdir/bar.rb', deep_commits.last.diffs[2].path
				assert_equal 'D', deep_commits.last.diffs[3].action
				assert_equal '/subdir/foo.rb', deep_commits.last.diffs[3].path
			end
		end

		# A mini-integration test.
		# Check that SHA1 values are populated, directories are recursed, and outside branches are ignored.
		def test_each_commit
			commits = []
			with_svn_repository('svn') do |svn|
				svn.each_commit do |e|
					commits << e
					assert e.token.to_s =~ /\d+/
					assert e.committer_name.length > 0
					assert e.committer_date.is_a?(Time)
					assert e.message
					assert e.diffs.any?
					e.diffs.each do |d|
						assert d.action.length == 1
						assert d.path.length > 0
					end
				end
				assert !FileTest.exist?(svn.log_filename) # Make sure we cleaned up after ourselves
			end

			assert_equal [1, 2, 3, 4, 5], commits.collect { |c| c.token }
			assert_equal ['robin','robin','robin','jason','jason'], commits.collect { |c| c.committer_name }

			assert_equal Time.utc(2006,6,11,18,28, 0), commits[0].committer_date
			assert_equal Time.utc(2006,6,11,18,32,14), commits[1].committer_date
			assert_equal Time.utc(2006,6,11,18,34,18), commits[2].committer_date
			assert_equal Time.utc(2006,7,14,22,17, 9), commits[3].committer_date
			assert_equal Time.utc(2006,7,14,23, 7,16), commits[4].committer_date

			assert_equal "Initial Checkin\n", commits[0].message
			assert_equal "added makefile", commits[1].message
			assert_equal "added some documentation and licensing info", commits[2].message
			assert_equal "added bs COPYING to catch global licenses", commits[3].message
			assert_equal "moving COPYING", commits[4].message

			assert_equal 1, commits[0].diffs.size
			assert_equal 'A', commits[0].diffs[0].action
			assert_equal '/trunk/helloworld.c', commits[0].diffs[0].path

			assert_equal 1, commits[1].diffs.size
			assert_equal 'A', commits[1].diffs[0].action
			assert_equal '/trunk/makefile', commits[1].diffs[0].path

			assert_equal 2, commits[2].diffs.size
			assert_equal 'A', commits[2].diffs[0].action
			assert_equal '/trunk/README', commits[2].diffs[0].path
			assert_equal 'M', commits[2].diffs[1].action
			assert_equal '/trunk/helloworld.c', commits[2].diffs[1].path

			assert_equal 1, commits[3].diffs.size
			assert_equal 'A', commits[3].diffs[0].action
			assert_equal '/COPYING', commits[3].diffs[0].path

			assert_equal 2, commits[4].diffs.size
			assert_equal 'D', commits[4].diffs[0].action
			assert_equal '/COPYING', commits[4].diffs[0].path
			assert_equal 'A', commits[4].diffs[1].action
			assert_equal '/trunk/COPYING', commits[4].diffs[1].path
		end

    def test_log_valid_encoding
      with_invalid_encoded_svn_repository do |svn|
        assert_equal true, svn.log.valid_encoding?
      end
    end

    def test_commits_encoding
      with_invalid_encoded_svn_repository do |svn|
        assert_nothing_raised do
          svn.commits rescue raise Exception
        end
      end
    end

    def test_open_log_file_encoding
      with_invalid_encoded_svn_repository do |svn|
        svn.open_log_file do |io|
          assert_equal true, io.read.valid_encoding?
        end
      end
    end

    def test_single_revision_xml_valid_encoding
      with_invalid_encoded_svn_repository do |svn|
        assert_equal true, svn.single_revision_xml(:anything).valid_encoding?
      end
    end
	end
end
