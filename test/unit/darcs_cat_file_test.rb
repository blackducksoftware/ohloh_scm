require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Adapters
	class DarcsCatFileTest < OhlohScm::Test

		def test_cat_file
			with_darcs_repository('darcs') do |darcs|
expected = <<-EXPECTED
/* Hello, World! */

/*
 * This file is not covered by any license, especially not
 * the GNU General Public License (GPL). Have fun!
 */

#include <stdio.h>
main()
{
	printf("Hello, World!\\\\n");
}
EXPECTED

				# The file was deleted by the "remove..." patch. Check that it does not exist now, but existed in parent.
				assert_equal nil, darcs.cat_file(Scm::Commit.new(:token => 'remove helloworld.c'), Scm::Diff.new(:path => 'helloworld.c'))
				assert_equal expected, darcs.cat_file_parent(Scm::Commit.new(:token => 'remove helloworld.c'), Scm::Diff.new(:path => 'helloworld.c'))
				assert_equal expected, darcs.cat_file(Scm::Commit.new(:token => 'add helloworld.c'), Scm::Diff.new(:path => 'helloworld.c'))
			end
		end

		# Ensure that we escape bash-significant characters like ' and & when they appear in the filename
                # NB only works with --reserved-ok, otherwise darcs rejects with "invalid under Windows"
		def test_funny_file_name_chars
			Scm::ScratchDir.new do |dir|
				# Make a file with a problematic filename
				funny_name = '|file_name (&\'")'
				File.open(File.join(dir, funny_name), 'w') { |f| f.write "contents" }

				# Add it to a darcs repository
				darcs = DarcsAdapter.new(:url => dir).normalize
				darcs.run("cd #{dir} && darcs init && darcs add --reserved-ok * && darcs record -a -m test")

				# Confirm that we can read the file back
				assert_equal "contents", darcs.cat_file(darcs.head, Scm::Diff.new(:path => funny_name))
			end
		end

	end
end
