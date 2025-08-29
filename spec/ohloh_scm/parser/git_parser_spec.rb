require 'spec_helper'

describe 'GitParser' do
  describe 'parse' do
    it 'must be empty for blank string' do
      assert_empty OhlohScm::GitParser.parse('')
    end

    it 'must return epoch time for log with no date' do
      sample_log = <<-SAMPLE.gsub(/^ {8}/, '')
        __BEGIN_COMMIT__
        Commit: 1df547800dcd168e589bb9b26b4039bff3a7f7e4
        Author: Jason Allen
        AuthorEmail: jason@ohloh.net
        Date:#{' '}
        __BEGIN_COMMENT__
            moving COPYING

        __END_COMMENT__
      SAMPLE
      commits = OhlohScm::GitParser.parse(sample_log)
      assert_equal commits.size, 1
      assert_equal commits[0].author_date, Time.utc(1970, 1, 1, 0, 0, 0)
    end

    it 'must return epoch time for log with invalid date' do
      sample_log = <<-SAMPLE.gsub(/^ {8}/, '')
        __BEGIN_COMMIT__
        Commit: 1df547800dcd168e589bb9b26b4039bff3a7f7e4
        Author: Jason Allen
        AuthorEmail: jason@ohloh.net
        Date: Mon, Jan 01 2012 05:00:00 -0500
        __BEGIN_COMMENT__
            moving COPYING

        __END_COMMENT__
      SAMPLE

      commits = OhlohScm::GitParser.parse(sample_log)
      assert_equal commits.size, 1
      assert_equal commits[0].author_date, Time.utc(1970, 1, 1, 0, 0, 0)
    end

    it 'must parse a log correctly' do
      sample_log = <<-SAMPLE.gsub(/^ {8}/, '')
        __BEGIN_COMMIT__
        Commit: 1df547800dcd168e589bb9b26b4039bff3a7f7e4
        Author: Jason Allen
        AuthorEmail: jason@ohloh.net
        Date:   Fri, 14 Jul 2006 16:07:15 -0700
        __BEGIN_COMMENT__
        moving COPYING

        __END_COMMENT__

        :000000 100755 0000000000000000000000000000000000000000 a7b13ff050aed1191c45d7a5db9a50edcdc5755f A	COPYING

        __BEGIN_COMMIT__
        Commit: 2e9366dd7a786fdb35f211fff1c8ea05c51968b1
        Author: Robin Luckey
        AuthorEmail: robin@ohloh.net
        Date:   Sun, 11 Jun 2006 11:34:17 -0700
        __BEGIN_COMMENT__
        added some documentation and licensing info

        __END_COMMENT__

        :100644 100644 d4a46caf1891fccebb726504f34794a0ca5d2e42 41dc0d12cb9eaa30e57aa7126b1227ba320ad297 M	README
        :100644 000000 41dc0d12cb9eaa30e57aa7126b1227ba320ad297 0000000000000000000000000000000000000000 D	helloworld.c
      SAMPLE

      commits = OhlohScm::GitParser.parse(sample_log)

      assert_equal commits.size, 2

      assert_equal commits[0].token, '1df547800dcd168e589bb9b26b4039bff3a7f7e4'
      assert_equal commits[0].author_name, 'Jason Allen'
      assert_equal commits[0].author_email, 'jason@ohloh.net'
      assert_equal commits[0].message, "moving COPYING\n"
      assert_equal commits[0].author_date, Time.utc(2006, 7, 14, 23, 7, 15)
      assert_equal commits[0].diffs.size, 1

      assert_equal commits[0].diffs[0].action, 'A'
      assert_equal commits[0].diffs[0].path, 'COPYING'

      assert_equal commits[1].token, '2e9366dd7a786fdb35f211fff1c8ea05c51968b1'
      assert_equal commits[1].author_name, 'Robin Luckey'
      assert_equal commits[1].author_email, 'robin@ohloh.net'
      assert_equal commits[1].message, "added some documentation and licensing info\n"
      assert_equal commits[1].author_date, Time.utc(2006, 6, 11, 18, 34, 17)
      assert_equal commits[1].diffs.size, 2

      assert_equal commits[1].diffs[0].action, 'M'
      assert_equal commits[1].diffs[0].path, 'README'
      assert_equal commits[1].diffs[1].action, 'D'
      assert_equal commits[1].diffs[1].path, 'helloworld.c'
    end
  end
end
