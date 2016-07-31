require_relative '../test_helper'

module OhlohScm::Parsers
	class BzrParserTest < OhlohScm::Test

		def test_empty_array
			assert_equal([], BzrParser.parse(''))
		end

		def test_default_log_parser
sample_log = <<SAMPLE
------------------------------------------------------------
revno: 2
committer: Robin <robin@ohloh.net>
branch nick: bzr
timestamp: Wed 2009-02-04 01:49:42 +0100
message:
  Second Revision
------------------------------------------------------------
revno: 1
committer: Jason <jason@ohloh.net>
branch nick: bzr
timestamp: Wed 2009-02-04 01:25:40 +0100
message:
  Initial Revision
SAMPLE

			commits = BzrParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal '2', commits[0].token
			assert_equal 'Robin', commits[0].committer_name
			assert_equal 'robin@ohloh.net', commits[0].committer_email
			assert_equal "Second Revision\n", commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2009,2,4,0,49,42), commits[0].committer_date
			assert_equal 0, commits[0].diffs.size

			assert_equal '1', commits[1].token
			assert_equal 'Jason', commits[1].committer_name
			assert_equal 'jason@ohloh.net', commits[1].committer_email
			assert_equal "Initial Revision\n", commits[1].message # Note \n at end of comment
			assert_equal Time.utc(2009,2,4,0,25,40), commits[1].committer_date
			assert_equal 0, commits[1].diffs.size
		end

		def test_verbose_log_parser
sample_log = <<SAMPLE
------------------------------------------------------------
revno: 2
committer: Robin <robin@ohloh.net>
branch nick: bzr
timestamp: Wed 2009-02-04 01:49:42 +0100
message:
  Second Revision
removed:
  file1.txt
modified:
  file2.txt
------------------------------------------------------------
revno: 1
committer: Jason <jason@ohloh.net>
branch nick: bzr
timestamp: Wed 2009-02-04 01:25:40 +0100
message:
  Initial Revision
added:
  file1.txt
  file2.txt
SAMPLE

			commits = BzrParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal '2', commits[0].token
			assert_equal 'Robin', commits[0].committer_name
			assert_equal 'robin@ohloh.net', commits[0].committer_email
			assert_equal "Second Revision\n", commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2009,2,4,0,49,42), commits[0].committer_date
			assert_equal 2, commits[0].diffs.size

			assert_equal 'file1.txt', commits[0].diffs[0].path
			assert_equal 'D', commits[0].diffs[0].action
			assert_equal 'file2.txt', commits[0].diffs[1].path
			assert_equal 'M', commits[0].diffs[1].action

			assert_equal '1', commits[1].token
			assert_equal 'Jason', commits[1].committer_name
			assert_equal 'jason@ohloh.net', commits[1].committer_email
			assert_equal "Initial Revision\n", commits[1].message # Note \n at end of comment
			assert_equal Time.utc(2009,2,4,0,25,40), commits[1].committer_date
			assert_equal 2, commits[1].diffs.size

			assert_equal 'file1.txt', commits[1].diffs[0].path
			assert_equal 'A', commits[1].diffs[0].action
			assert_equal 'file2.txt', commits[1].diffs[1].path
			assert_equal 'A', commits[1].diffs[1].action
		end

		def test_verbose_log_parser_with_show_id
sample_log = <<SAMPLE
------------------------------------------------------------
revno: 2
revision-id: info@ohloh.net-20090204004942-73rnw0izen42f154
parent: info@ohloh.net-20090204002540-gmana8tk5f9gboq9
committer: Robin <robin@ohloh.net>
branch nick: bzr
timestamp: Wed 2009-02-04 01:49:42 +0100
message:
  Second Revision
removed:
  file1.txt                      file1.txt-20090204002338-awfasrgh9nuzc53d-1
modified:
  file2.txt                      file2.txt-20090204002419-s025jc9k05dghk6d-1
------------------------------------------------------------
revno: 1
revision-id: info@ohloh.net-20090204002540-gmana8tk5f9gboq9
parent: info@ohloh.net-20090204002518-yb0x153oa6mhoodu
committer: Jason <jason@ohloh.net>
branch nick: bzr
timestamp: Wed 2009-02-04 01:25:40 +0100
message:
  Initial Revision
added:
  file1.txt                      file1.txt-20090204002338-awfasrgh9nuzc53d-1
  file2.txt                      file2.txt-20090204002419-s025jc9k05dghk6d-1
SAMPLE

			commits = BzrParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal 'info@ohloh.net-20090204004942-73rnw0izen42f154', commits[0].token
			assert_equal 'Robin', commits[0].committer_name
			assert_equal 'robin@ohloh.net', commits[0].committer_email
			assert_equal "Second Revision\n", commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2009,2,4,0,49,42), commits[0].committer_date
			assert_equal 2, commits[0].diffs.size

			assert_equal 'file1.txt', commits[0].diffs[0].path
			assert_equal 'D', commits[0].diffs[0].action
			assert_equal 'file2.txt', commits[0].diffs[1].path
			assert_equal 'M', commits[0].diffs[1].action

			assert_equal 'info@ohloh.net-20090204002540-gmana8tk5f9gboq9', commits[1].token
			assert_equal 'Jason', commits[1].committer_name
			assert_equal 'jason@ohloh.net', commits[1].committer_email
			assert_equal "Initial Revision\n", commits[1].message # Note \n at end of comment
			assert_equal Time.utc(2009,2,4,0,25,40), commits[1].committer_date
			assert_equal 2, commits[1].diffs.size

			assert_equal 'file1.txt', commits[1].diffs[0].path
			assert_equal 'A', commits[1].diffs[0].action
			assert_equal 'file2.txt', commits[1].diffs[1].path
			assert_equal 'A', commits[1].diffs[1].action
		end

		def test_verbose_log_parser_very_long_filename_with_show_id
sample_log = <<SAMPLE
------------------------------------------------------------
revno: 1
revision-id: info@ohloh.net-20090204002540-gmana8tk5f9gboq9
parent: info@ohloh.net-20090204002518-yb0x153oa6mhoodu
committer: Jason <jason@ohloh.net>
branch nick: bzr
timestamp: Wed 2009-02-04 01:25:40 +0100
message:
  Initial Revision
added:
  a very long filename with space intended to cause log parsing problems averylongfilenamewit-20090205232320-4fl43j6djs9pfnn4-1
SAMPLE

			commits = BzrParser.parse(sample_log)

			assert commits
			assert_equal 1, commits.size

			assert_equal 'info@ohloh.net-20090204002540-gmana8tk5f9gboq9', commits[0].token
			assert_equal 'Jason', commits[0].committer_name
			assert_equal 'jason@ohloh.net', commits[0].committer_email
			assert_equal "Initial Revision\n", commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2009,2,4,0,25,40), commits[0].committer_date

			assert_equal 1, commits[0].diffs.size
			assert_equal 'a very long filename with space intended to cause log parsing problems', commits[0].diffs[0].path
			assert_equal 'A', commits[0].diffs[0].action
		end

		def test_verbose_log_with_nested_merge_commits
sample_log = <<SAMPLE
------------------------------------------------------------
revno: 16
revision-id: robin@ohloh.net-20080629125019-qxk9qma8esphwwus
parent: robin@ohloh.net-20080629121849-2le5txjj7tkdq54f
parent: robin@ohloh.net-20080630050459-ox7a50k5qi6tg2z2
committer: robin <robin@ohloh.net>
branch nick: ohloh
timestamp: Sun 2008-06-29 05:50:19 -0700
message:
  Committing merge
removed:
  goodbye_world.c                goodbye_world.c-20080625052902-61bbthtf22shh0p6-293
    ------------------------------------------------------------
    revno: 12.1.2
    revision-id: robin@ohloh.net-20080629214643-5ru67mh04j09cmiz
    parent: robin@ohloh.net-20080629201028-923bdzz0qcjmd6cm
    committer: robin <robin@ohloh.net>
    branch nick: ohloh
    timestamp: Sun 2008-06-29 14:46:43 -0700
    message:
      Second commit on branch
    modified:
      hello_world.c                  hello_world.c-20080625052902-61bbthtf22shh0p6-447
    ------------------------------------------------------------
    revno: 12.1.1
    revision-id: robin@ohloh.net-20080629201028-923bdzz0qcjmd6cm
    parent: robin@ohloh.net-20080629191920-ioqljg6ihntzcz9y
    committer: robin <robin@ohloh.net>
    branch nick: ohloh
    timestamp: Sun 2008-06-29 13:10:28 -0700
    message:
      First commit on branch
    added:
      goodbye_world.c                goodbye_world.c-20080625052902-61bbthtf22shh0p6-422
------------------------------------------------------------
revno: 15
revision-id: robin@ohloh.net-20080629121849-2le5txjj7tkdq54f
parent: robin@ohloh.net-20080629092342-7jfxn10e2qchi931
committer: robin <robin@ohloh.net>
branch nick: ohloh
timestamp: Sun 2008-06-29 05:18:49 -0700
message:
  First commit on trunk
modified:
  hello_world.c                  hello_world.c-20080625052902-61bbthtf22shh0p6-293
SAMPLE
			commits = BzrParser.parse(sample_log)

			assert commits
			assert_equal 4, commits.size

			assert_equal 'robin@ohloh.net-20080629125019-qxk9qma8esphwwus', commits[0].token
			assert_equal 'robin@ohloh.net-20080629214643-5ru67mh04j09cmiz', commits[1].token
			assert_equal 'robin@ohloh.net-20080629201028-923bdzz0qcjmd6cm', commits[2].token
			assert_equal 'robin@ohloh.net-20080629121849-2le5txjj7tkdq54f', commits[3].token

			assert_equal 1, commits[0].diffs.size
			assert_equal 'goodbye_world.c', commits[0].diffs[0].path
			assert_equal 'D', commits[0].diffs[0].action

			assert_equal 1, commits[1].diffs.size
			assert_equal 'hello_world.c', commits[1].diffs[0].path
			assert_equal 'M', commits[1].diffs[0].action

			assert_equal 1, commits[2].diffs.size
			assert_equal 'goodbye_world.c', commits[2].diffs[0].path
			assert_equal 'A', commits[2].diffs[0].action

			assert_equal 1, commits[3].diffs.size
			assert_equal 'hello_world.c', commits[3].diffs[0].path
			assert_equal 'M', commits[3].diffs[0].action
		end

		def test_parse_diffs
			assert_equal 'A', BzrParser.parse_diffs('A', "helloworld.c").first.action
			assert_equal 'helloworld.c', BzrParser.parse_diffs('A', "helloworld.c").first.path
		end

		def test_parse_diffs_rename
			diffs = BzrParser.parse_diffs(:rename, "helloworld.c => goodbyeworld.c")
			assert_equal 2, diffs.size
			assert_equal 'D', diffs.first.action
			assert_equal 'helloworld.c', diffs.first.path
			assert_equal 'A', diffs.last.action
			assert_equal 'goodbyeworld.c', diffs.last.path
		end

		def test_rename
			log = <<-SAMPLE
------------------------------------------------------------
revno: 2
committer: info <info@ohloh.net>
timestamp: Wed 2005-09-14 21:27:20 +1000
message:
  rename a file
renamed:
  helloworld.c => goodbyeworld.c
			SAMPLE

			commits = BzrParser.parse(log)

			assert commits
			assert_equal 1, commits.size
			assert_equal 2, commits.first.diffs.size

			assert_equal 'D', commits.first.diffs.first.action
			assert_equal 'helloworld.c', commits.first.diffs.first.path

			assert_equal 'A', commits.first.diffs.last.action
			assert_equal 'goodbyeworld.c', commits.first.diffs.last.path
		end

		def test_remove_dupes_add_remove
			diffs = BzrParser.remove_dupes([ OhlohScm::Diff.new(:action => "A", :path => "foo"),
																				OhlohScm::Diff.new(:action => "D", :path => "foo") ])
			assert_equal 1, diffs.size
			assert_equal 'M', diffs.first.action
			assert_equal 'foo', diffs.first.path
		end

		# A somewhat tricky case. A file is deleted, and another
		# file is renamed to take its place. That file is then modified!
		#
		# This is what Ohloh expects to see:
		#
		#   D  goodbyeworld.c
		#   M  helloworld.c
		#
		def test_complex_rename
			log = <<-SAMPLE
------------------------------------------------------------
revno: 147.1.24
committer: info <info@ohloh.net>
timestamp: Wed 2005-09-14 21:27:20 +1000
message:
  rename a file to replace an existing one, then modify it!
removed:
  helloworld.c
renamed:
  goodbyeworld.c => helloworld.c
modified:
  helloworld.c
			SAMPLE

			diffs = BzrParser.parse(log).first.diffs
			diffs.sort! { |a,b| a.path <=> b.path }

			assert_equal 2, diffs.size
			assert_equal 'D', diffs.first.action
			assert_equal 'goodbyeworld.c', diffs.first.path
			assert_equal 'M', diffs.last.action
			assert_equal 'helloworld.c', diffs.last.path
		end

		def test_strip_trailing_asterisk_from_executables
			log = <<-SAMPLE
------------------------------------------------------------
revno: 1
committer: info <info@ohloh.net>
timestamp: Wed 2005-09-14 21:27:20 +1000
message:
  added an executable, also renamed an executable
added:
  script*
renamed:
  helloworld* => goodbyeworld*
			SAMPLE

			diffs = BzrParser.parse(log).first.diffs
			diffs.sort! { |a,b| a.path <=> b.path }

			assert_equal 'goodbyeworld', diffs[0].path
			assert_equal 'helloworld', diffs[1].path
			assert_equal 'script', diffs[2].path
		end

		def test_comment_that_contains_dashes
			log = <<-SAMPLE
------------------------------------------------------------
revno: 2
committer: info <info@ohloh.net>
timestamp: Wed 2005-09-14 21:27:20 +1000
message:
  This is a tricky commit message to confirm fix
  to Ticket 5. We're including a line of dashes in
  the message that resembles a log delimiter.

  ------------------------------------------------------------

	Happy parsing!
added:
  goodbyeworld.c
------------------------------------------------------------
revno: 1
committer: info <info@ohloh.net>
timestamp: Wed 2005-09-14 21:27:20 +1000
message:
  Initial Revision
added:
  helloworld.c
			SAMPLE

			commits = BzrParser.parse(log)

			assert_equal 2, commits.size
			assert_equal '2', commits.first.token
			assert_equal 1, commits.first.diffs.size
			assert_equal "goodbyeworld.c", commits.first.diffs.first.path

			assert_equal '1', commits.last.token
			assert_equal 1, commits.last.diffs.size
			assert_equal "helloworld.c", commits.last.diffs.first.path
		end

		# In this example, directory "test/" is renamed to "/".
		# This shows in the log as being renamed to an empty string.
		def test_directory_renamed_to_root
			log = <<-SAMPLE
        ------------------------------------------------------------
        revno: 220.90.1
        revision-id: info@ohloh.net-20081002201109-j4z0r2c8nsgbm2vk
        parent: info@ohloh.net-20081002200737-pjao1idjcrxpk4n4
        committer: Ohloh <info@ohloh.net>
        branch nick: subvertpy
        timestamp: Thu 2008-10-02 22:11:09 +0200
        message:
          Promote the test directory to the root.
        renamed:
          test =>  test-20081002184530-hz9mrr3wqq4l8qdx-1
			SAMPLE

			commits = BzrParser.parse(log)

			assert_equal 1, commits.size
			assert_equal 'info@ohloh.net-20081002201109-j4z0r2c8nsgbm2vk', commits.first.token
			assert_equal 2, commits.first.diffs.size
			assert_equal "D", commits.first.diffs.first.action
			assert_equal "test", commits.first.diffs.first.path
			assert_equal "A", commits.first.diffs.last.action
			assert_equal "", commits.first.diffs.last.path
		end

		# It is possible for Bzr to report a file as both renamed and modified
		# in the same commit. We should treat this as only a rename -- that is, we
		# should see a simple DELETE from the old location and an ADD to the new location.
		def test_rename_and_modify_in_one_commit
			log = <<-SAMPLE
------------------------------------------------------------
revno: 1
message:
  Changed the directory structure
renamed:
  oldname => newname
modified:
  newname
			SAMPLE

			commits = BzrParser.parse(log)

			assert_equal 1, commits.size
			assert_equal 2, commits.first.diffs.size
			assert_equal "D", commits.first.diffs.first.action
			assert_equal "oldname", commits.first.diffs.first.path
			assert_equal "A", commits.first.diffs.last.action
			assert_equal "newname", commits.first.diffs.last.path
		end

		def test_different_author_and_committer
			log = <<-SAMPLE
------------------------------------------------------------
revno: 200
author: Jason Allen <jason@ohloh.net>
committer: Robin Luckey <robin@ohloh.net>
branch nick: foo
timestamp: Wed 2009-06-24 19:47:37 +0200
message:
	  Just a message
			SAMPLE

			commits = BzrParser.parse(log)

			assert_equal 1, commits.size
			assert_equal "Jason Allen", commits.first.author_name
			assert_equal "jason@ohloh.net", commits.first.author_email
			assert_equal "Robin Luckey", commits.first.committer_name
			assert_equal "robin@ohloh.net", commits.first.committer_email
		end
	end
end
