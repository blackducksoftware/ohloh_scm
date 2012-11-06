require File.dirname(__FILE__) + '/../test_helper'

module Scm::Parsers
  class MtnRevisionParserTest < Scm::Test

    def test_empty_array
      assert_equal([], MtnRevisionParser.parse(''))
    end

    def test_log_parser_default
      sample_log = <<SAMPLE
format_version "1"

new_manifest [4b1cc487776307f86103e5426ed4b50b68938662]

old_revision [ced0b8c900531859b64eb632549666a38c89d7a0]

add_file "NEWS"
 content [e86ff17788d06ed770b3f87ad8410e99ba958c2e]

patch "INSTALL"
 from [5bb6b21794257124ce40b682450a54010b7de61c]
   to [8a79847fb9758bc777afcae87b7165bb417360bc]

delete "dummyText"

rename "src/faake"
    to "src/fake"
SAMPLE

      diffs = MtnRevisionParser.parse(sample_log)

      assert diffs
      assert_equal 5, diffs.size

      assert_equal 'NEWS', diffs[0].path
      assert_equal 'A', diffs[0].action
      assert_equal 'e86ff17788d06ed770b3f87ad8410e99ba958c2e', diffs[0].sha1

      assert_equal 'INSTALL', diffs[1].path
      assert_equal 'M', diffs[1].action
      assert_equal '5bb6b21794257124ce40b682450a54010b7de61c', diffs[1].parent_sha1
      assert_equal '8a79847fb9758bc777afcae87b7165bb417360bc', diffs[1].sha1

      assert_equal 'dummyText', diffs[2].path
      assert_equal 'D', diffs[2].action

      assert_equal 'src/faake', diffs[3].path
      assert_equal 'D', diffs[3].action

      assert_equal 'src/fake', diffs[4].path
      assert_equal 'A', diffs[4].action

    end
  end
end
