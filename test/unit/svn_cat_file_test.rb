require_relative '../test_helper'

module OhlohScm::Adapters
	class SvnCatFileTest < OhlohScm::Test

		def test_cat_file
			with_svn_repository('svn') do |svn|
expected = <<-EXPECTED
/* Hello, World! */
#include <stdio.h>
main()
{
	printf("Hello, World!\\n");
}
EXPECTED
				assert_equal expected, svn.cat_file(OhlohScm::Commit.new(:token => 1), OhlohScm::Diff.new(:path => "trunk/helloworld.c"))

				assert_equal nil, svn.cat_file(OhlohScm::Commit.new(:token => 1), OhlohScm::Diff.new(:path => "file not found"))
			end
		end
	end
end
