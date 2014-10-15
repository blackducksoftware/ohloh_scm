require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Parsers
	class DarcsParserTest < OhlohScm::Test

		def test_empty_array
			assert_equal([], DarcsParser.parse(''))
		end

		def test_log_parser_default
sample_log = <<SAMPLE
Wed Nov  3 15:55:25 PDT 2010  Simon Michael <simon@joyful.com>
  * remove helloworld.c

Wed Nov  3 15:49:53 PDT 2010  Simon Michael <simon@joyful.com>
  * add helloworld.c

SAMPLE

			commits = DarcsParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal 'remove helloworld.c', commits[0].token
			assert_equal 'Simon Michael', commits[0].author_name
			assert_equal 'simon@joyful.com', commits[0].author_email
			assert_equal nil, commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2010,11,3,22,55,25), commits[0].author_date
			assert_equal 0, commits[0].diffs.size

			assert_equal 'add helloworld.c', commits[1].token
			assert_equal 'Simon Michael', commits[1].author_name
			assert_equal 'simon@joyful.com', commits[1].author_email
			assert_equal nil, commits[1].message # Note \n at end of comment
			assert_equal Time.utc(2010,11,3,22,49,53), commits[1].author_date
			assert_equal 0, commits[1].diffs.size
		end

		def test_log_parser_default_partial_user_name
sample_log = <<SAMPLE
Wed Nov  3 15:55:25 PDT 2010  Simon Michael
  * name only

Wed Nov  3 15:49:53 PDT 2010  simon@joyful.com
  * email only

SAMPLE

			commits = DarcsParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal 'name only', commits[0].token
			assert_equal 'Simon Michael', commits[0].author_name
			assert !commits[0].author_email

			assert_equal 'email only', commits[1].token
			assert !commits[1].author_name
			assert_equal 'simon@joyful.com', commits[1].author_email
		end

		def test_log_parser_verbose
sample_log = <<SAMPLE
Wed Nov  3 15:55:25 PDT 2010  Simon Michael <simon@joyful.com>
  * remove helloworld.c
    hunk ./helloworld.c 1
    -/* Hello, World! */
    -
    -/*
    - * This file is not covered by any license, especially not
    - * the GNU General Public License (GPL). Have fun!
    - */
    -
    -#include <stdio.h>
    -main()
    -{
    -	printf("Hello, World!\\n");
    -}
    rmfile ./helloworld.c

Wed Nov  3 15:49:53 PDT 2010  Simon Michael <simon@joyful.com>
  * add helloworld.c
    addfile ./helloworld.c
    hunk ./helloworld.c 1
    +/* Hello, World! */
    +
    +/*
    + * This file is not covered by any license, especially not
    + * the GNU General Public License (GPL). Have fun!
    + */
    +
    +#include <stdio.h>
    +main()
    +{
    +	printf("Hello, World!\\n");
    +}
SAMPLE

			commits = DarcsParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal 'remove helloworld.c', commits[0].token
			assert_equal 'Simon Michael', commits[0].author_name
			assert_equal 'simon@joyful.com', commits[0].author_email
			assert_equal nil, commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2010,11,3,22,55,25), commits[0].author_date
			assert_equal 2, commits[0].diffs.size
			assert_equal './helloworld.c', commits[0].diffs[0].path
			assert_equal './helloworld.c', commits[0].diffs[1].path

			assert_equal 'add helloworld.c', commits[1].token
			assert_equal 'Simon Michael', commits[1].author_name
			assert_equal 'simon@joyful.com', commits[1].author_email
			assert_equal nil, commits[1].message # Note \n at end of comment
			assert_equal Time.utc(2010,11,3,22,49,53), commits[1].author_date
			assert_equal 2, commits[0].diffs.size
			assert_equal './helloworld.c', commits[0].diffs[0].path
			assert_equal './helloworld.c', commits[0].diffs[1].path
		end

		protected

	end
end
