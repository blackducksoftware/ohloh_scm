require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Parsers
  class MtnCertsParserTest < Scm::Adapters::MtnAbstractTest

    def test_empty_array
      assert_equal([], MtnCertsParser.parse(''))
    end

    def test_log_parser_default
      sample_log = <<SAMPLE
      key [4bee20e697b0985fa98208d30d4926501fca762f]
signature "ok"
     name "author"
    value "richhguard-monotone@yahoo.co.uk"
    trust "trusted"

      key [4bee20e697b0985fa98208d30d4926501fca762f]
signature "ok"
     name "branch"
    value "net.venge.monotone"
    trust "trusted"

      key [4bee20e697b0985fa98208d30d4926501fca762f]
signature "ok"
     name "changelog"
    value "Add required packages for OpenBSD to INSTALL"
    trust "trusted"

      key [4bee20e697b0985fa98208d30d4926501fca762f]
signature "ok"
     name "date"
    value "2012-09-23T10:41:52"
    trust "trusted"
SAMPLE

      commits = MtnCertsParser.parse(sample_log)

      assert commits
      assert_equal 1, commits.size

      #			assert_equal 'b14fa4692f94', commits[0].token
      assert_equal 'richhguard-monotone@yahoo.co.uk', commits[0].author_name
      assert_equal 'richhguard-monotone@yahoo.co.uk', commits[0].author_email
      assert_equal "Add required packages for OpenBSD to INSTALL", commits[0].message # Note \n at end of comment
      assert_equal Time.utc(2012,9,23,10,41,52), commits[0].author_date
    end
  end
end
