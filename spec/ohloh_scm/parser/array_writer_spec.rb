require 'spec_helper'

describe 'ArrayWriter' do
  it 'must work' do
    log = <<-LOG.gsub(/^ {6}/, '')
      __BEGIN_COMMIT__
      Commit: 1df547800dcd168e589bb9b26b4039bff3a7f7e4
      Author: Jason Allen
      AuthorEmail: jason@ohloh.net
      Date:   Fri, 14 Jul 2006 16:07:15 -0700
      __BEGIN_COMMENT__
      moving COPYING

      __END_COMMENT__

      :000000 100755 0000000000000000000000000000000000000000 a7b13ff050aed1191c45d7a5db9a50edcdc5755f A	COPYING
    LOG

    commits = OhlohScm::GitParser.parse(log)
    assert_equal commits.size, 1
    commit = commits.first
    assert_equal commit.token, '1df547800dcd168e589bb9b26b4039bff3a7f7e4'
    assert_equal commit.author_name, 'Jason Allen'
    assert_equal commit.author_email, 'jason@ohloh.net'
    assert_equal commit.message, "moving COPYING\n"
    assert_equal commit.author_date, Time.utc(2006, 7, 14, 23, 7, 15)
    assert_equal commit.diffs.size, 1
  end
end
