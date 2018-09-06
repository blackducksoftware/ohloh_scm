require_relative '../test_helper'

module OhlohScm::Adapters
	class CvsMiscTest < OhlohScm::Test
		def test_local_directory_trim
			r = CvsAdapter.new(:url => "/Users/robin/cvs_repo/", :module_name => "simple")
			assert_equal "/Users/robin/cvs_repo/simple/foo.rb", r.trim_directory('/Users/robin/cvs_repo/simple/foo.rb')
		end

		def test_remote_directory_trim
			r = CvsAdapter.new(:url => ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle', :module_name => "contrib")
			assert_equal "foo.rb", r.trim_directory('/cvsroot/moodle/contrib/foo.rb')
		end

		def test_remote_directory_trim_with_port_number
			r = CvsAdapter.new(:url => ':pserver:anoncvs:anoncvs@libvirt.org:2401/data/cvs', :module_name => "libvirt")
			assert_equal "docs/html/Attic", r.trim_directory('/data/cvs/libvirt/docs/html/Attic')
		end

		def test_ordered_directory_list
			r = CvsAdapter.new(:url => ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle', :module_name => "contrib")

			l = r.build_ordered_directory_list(["/cvsroot/moodle/contrib/foo/bar".intern,
																				"/cvsroot/moodle/contrib".intern,
																				"/cvsroot/moodle/contrib/hello".intern,
																				"/cvsroot/moodle/contrib/hello".intern])

			assert_equal 4,l.size
			assert_equal "", l[0]
			assert_equal "foo", l[1]
			assert_equal "hello", l[2]
			assert_equal "foo/bar", l[3]
		end

		def test_ordered_directory_list_ignores_Attic
			r = CvsAdapter.new(:url => ':pserver:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle', :module_name => 'contrib')

			l = r.build_ordered_directory_list(["/cvsroot/moodle/contrib/foo/bar".intern,
																				"/cvsroot/moodle/contrib/Attic".intern,
																				"/cvsroot/moodle/contrib/hello/Attic".intern])

			assert_equal 4,l.size
			assert_equal "", l[0]
			assert_equal "foo", l[1]
			assert_equal "hello", l[2]
			assert_equal "foo/bar", l[3]
		end

    def host
			r = CvsAdapter.new(:url => ':ext:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle', :module_name => 'contrib')
      assert_equal 'moodle.cvs.sourceforge.net', r.host
    end

    def protocol
      assert_equal :pserver, CvsAdapter.new(:url => ':pserver:foo:@foo.com:/cvsroot/a', :module_name => 'b')
      assert_equal :ext, CvsAdapter.new(:url => ':ext:foo:@foo.com:/cvsroot/a', :module_name => 'b')
      assert_equal :pserver, CvsAdapter.new(:url => ':pserver:ext:@foo.com:/cvsroot/a', :module_name => 'b')
    end

    def test_tags
      with_cvs_repository('cvs', 'simple') do |cvs|
        assert_equal([['simple_release_tag', '1.1.1.1'], ['simple_vendor_tag', '1.1.1']], cvs.tags)
      end
    end

    def test_export_tag
      with_cvs_repository('cvs', 'simple') do |cvs|
        OhlohScm::ScratchDir.new do |dir|
          cvs.export_tag(dir, 'simple_release_tag')

          assert_equal ['.','..','foo.rb'], Dir.entries(dir).sort
        end
      end
    end
	end
end
