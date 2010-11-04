require File.dirname(__FILE__) + '/../test_helper'

module Scm::Parsers
	class DarcsParserTest < Scm::Test

		def test_empty_array
			assert_equal([], DarcsParser.parse(''))
		end

		def test_log_parser_default
sample_log = <<SAMPLE
changeset:   1:b14fa4692f94
user:        Jason Allen <jason@ohloh.net>
date:        Tue, Jan 20 2009 11:33:17 -0800
summary:     added makefile


changeset:   0:01101d8ef3ce
user:        Robin Luckey <robin@ohloh.net>
date:        Tue, Jan 20 2009 11:32:54 -0800
summary:     Initial Checkin

SAMPLE

			commits = DarcsParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal 'b14fa4692f94', commits[0].token
			assert_equal 'Jason Allen', commits[0].committer_name
			assert_equal 'jason@ohloh.net', commits[0].committer_email
			assert_equal "added makefile", commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2009,1,20,19,33,17), commits[0].committer_date
			assert_equal 0, commits[0].diffs.size

			assert_equal '01101d8ef3ce', commits[1].token
			assert_equal 'Robin Luckey', commits[1].committer_name
			assert_equal 'robin@ohloh.net', commits[1].committer_email
			assert_equal "Initial Checkin", commits[1].message # Note \n at end of comment
			assert_equal Time.utc(2009,1,20,19,32,54), commits[1].committer_date
			assert_equal 0, commits[1].diffs.size
		end

		def test_log_parser_default_partial_user_name
sample_log = <<SAMPLE
changeset:   259:45c293b71341
user:        robin@ohloh.net
date:        Sat, Jun 04 2005 23:37:11 -0800
summary:     fix addremove

SAMPLE

			commits = DarcsParser.parse(sample_log)

			assert commits
			assert_equal 1, commits.size

			assert_equal '45c293b71341', commits[0].token
			assert_equal 'robin@ohloh.net', commits[0].committer_name
			assert !commits[0].committer_email
		end

		# Sometimes the log does not include a summary
		def test_log_parser_default_no_summary
sample_log = <<SAMPLE
changeset:   1:b14fa4692f94
user:        Jason Allen <jason@ohloh.net>
date:        Tue, Jan 20 2009 11:33:17 -0800


changeset:   0:01101d8ef3ce
user:        Robin Luckey <robin@ohloh.net>
date:        Tue, Jan 20 2009 11:32:54 -0800

SAMPLE
			commits = DarcsParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal 'b14fa4692f94', commits[0].token
			assert_equal 'Jason Allen', commits[0].committer_name
			assert_equal 'jason@ohloh.net', commits[0].committer_email
			assert_equal Time.utc(2009,1,20,19,33,17), commits[0].committer_date
			assert_equal 0, commits[0].diffs.size

			assert_equal '01101d8ef3ce', commits[1].token
			assert_equal 'Robin Luckey', commits[1].committer_name
			assert_equal 'robin@ohloh.net', commits[1].committer_email
			assert_equal Time.utc(2009,1,20,19,32,54), commits[1].committer_date
			assert_equal 0, commits[1].diffs.size
		end

		def test_log_parser_verbose
sample_log = <<SAMPLE
changeset:   1:b14fa4692f94
user:        Jason Allen <jason@ohloh.net>
date:        Tue, Jan 20 2009 11:33:17 -0800
files:       makefile
description:
added makefile


changeset:   0:01101d8ef3ce
user:        Robin Luckey <robin@ohloh.net>
date:        Tue, Jan 20 2009 11:32:54 -0800
files:       helloworld.c
description:
Initial Checkin


SAMPLE

			commits = DarcsParser.parse(sample_log)

			assert commits
			assert_equal 2, commits.size

			assert_equal 'b14fa4692f94', commits[0].token
			assert_equal 'Jason Allen', commits[0].committer_name
			assert_equal 'jason@ohloh.net', commits[0].committer_email
			assert_equal "added makefile\n", commits[0].message # Note \n at end of comment
			assert_equal Time.utc(2009,1,20,19,33,17), commits[0].committer_date
			assert_equal 1, commits[0].diffs.size
			assert_equal 'makefile', commits[0].diffs[0].path

			assert_equal '01101d8ef3ce', commits[1].token
			assert_equal 'Robin Luckey', commits[1].committer_name
			assert_equal 'robin@ohloh.net', commits[1].committer_email
			assert_equal "Initial Checkin\n", commits[1].message # Note \n at end of comment
			assert_equal Time.utc(2009,1,20,19,32,54), commits[1].committer_date
			assert_equal 1, commits[1].diffs.size
			assert_equal 'helloworld.c', commits[1].diffs[0].path
		end

		def test_styled_parser
			with_darcs_repository('darcs') do |darcs|
				assert FileTest.exist?(DarcsStyledParser.style_path)
				log = darcs.run("cd #{darcs.url} && darcs log --style #{Scm::Parsers::DarcsStyledParser.style_path}")
				commits = Scm::Parsers::DarcsStyledParser.parse(log)
				assert_styled_commits(commits, false)

				assert FileTest.exist?(DarcsStyledParser.verbose_style_path)
				log = darcs.run("cd #{darcs.url} && darcs log --style #{Scm::Parsers::DarcsStyledParser.verbose_style_path}")
				commits = Scm::Parsers::DarcsStyledParser.parse(log)
				assert_styled_commits(commits, true)
			end
		end

		protected

		def assert_styled_commits(commits, with_diffs=false)
			assert_equal 4, commits.size

			assert_equal '75532c1e1f1de55c2271f6fd29d98efbe35397c4', commits[0].token
			assert_equal 'Robin Luckey', commits[0].committer_name
			assert_equal 'robin@ohloh.net', commits[0].committer_email
			assert Time.utc(2009,1,20,19,34,53) - commits[0].committer_date < 1 # Don't care about milliseconds
			assert_equal "deleted helloworld.c\n", commits[0].message

			if with_diffs
				assert_equal 1, commits[0].diffs.size
				assert_equal 'D', commits[0].diffs[0].action
				assert_equal 'helloworld.c', commits[0].diffs[0].path
			else
				assert_equal [], commits[0].diffs
			end

			assert_equal '468336c6671cbc58237a259d1b7326866afc2817', commits[1].token
			assert Time.utc(2009, 1,20,19,34,04) - commits[1].committer_date < 1

			if with_diffs
				assert_equal 2, commits[1].diffs.size
				assert_equal 'M', commits[1].diffs[0].action
				assert_equal 'helloworld.c', commits[1].diffs[0].path
				assert_equal 'A', commits[1].diffs[1].action
				assert_equal 'README', commits[1].diffs[1].path
			else
				assert_equal [], commits[0].diffs
			end
		end
	end
end
