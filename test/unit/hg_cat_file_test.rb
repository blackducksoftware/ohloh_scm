require_relative '../test_helper'

module OhlohScm::Adapters
	class HgCatFileTest < OhlohScm::Test

		def test_cat_file
			with_hg_repository('hg') do |hg|
expected = <<-EXPECTED
/* Hello, World! */

/*
 * This file is not covered by any license, especially not
 * the GNU General Public License (GPL). Have fun!
 */

#include <stdio.h>
main()
{
	printf("Hello, World!\\n");
}
EXPECTED

				# The file was deleted in revision 468336c6671c. Check that it does not exist now, but existed in parent.
				assert_equal nil, hg.cat_file(OhlohScm::Commit.new(:token => '75532c1e1f1d'), OhlohScm::Diff.new(:path => 'helloworld.c'))
				assert_equal expected, hg.cat_file_parent(OhlohScm::Commit.new(:token => '75532c1e1f1d'), OhlohScm::Diff.new(:path => 'helloworld.c'))
				assert_equal expected, hg.cat_file(OhlohScm::Commit.new(:token => '468336c6671c'), OhlohScm::Diff.new(:path => 'helloworld.c'))
			end
		end

		# Ensure that we escape bash-significant characters like ' and & when they appear in the filename
		def test_funny_file_name_chars
			OhlohScm::ScratchDir.new do |dir|
				# Make a file with a problematic filename
				funny_name = '#|file_name` $(&\'")#'
				File.open(File.join(dir, funny_name), 'w') { |f| f.write "contents" }

				# Add it to an hg repository
				`cd #{dir} && hg init && hg add * && hg commit -u tester -m test`

				# Confirm that we can read the file back
				hg = HgAdapter.new(:url => dir).normalize
				assert_equal "contents", hg.cat_file(hg.head, OhlohScm::Diff.new(:path => funny_name))
			end
		end

	end
end
