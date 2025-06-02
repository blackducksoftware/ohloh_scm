# frozen_string_literal: true

require 'spec_helper'

describe 'Git::Activity' do
  it 'must export contents of a repository' do
    with_git_repository('git') do |git|
      tmpdir do |dir|
        git.activity.export(dir)
        entries = ['.', '..', '.gitignore', 'COPYING', 'Gemfile.lock', 'Godeps', 'README',
                   'helloworld.c', 'makefile', 'nested', 'ohloh_token']
        assert_equal Dir.entries(dir).sort, entries
      end
    end
  end

  it 'export must work the same for tag or commit_sha' do
    with_git_repository('git') do |git|
      tag_sha = 'f6e5a894ac4173f8f2a200f2c36df38a1e61121a'
      commit_sha = `cd #{git.scm.url} && git show #{tag_sha}`.slice(/commit (.+)$/, 1)

      Dir.mktmpdir('oh_scm_tag_') do |tag_dir|
        git.activity.export(tag_dir, tag_sha)

        Dir.mktmpdir('oh_scm_commit_') do |commit_dir|
          git.activity.export(commit_dir, commit_sha)
          assert_empty `diff -rq #{tag_dir} #{commit_dir}`
          assert_equal Dir.entries(commit_dir).sort, ['.', '..', '.gitignore', 'helloworld.c',
                                                      'makefile', 'ohloh_token']
        end
      end
    end
  end

  it 'must encode branch names correctly' do
    with_git_repository('git_with_invalid_encoding') do |git|
      assert git.activity.send(:branches).all?(&:valid_encoding?)
    end
  end

  describe 'tags' do
    it 'scm test fixture must have dereferenced tags' do
      with_git_repository('git') do |git|
        tag_shas = `cd #{git.scm.url} && git tag --format='%(objectname)' | sed 's/refs\\/tags\\///'`.split("\n")
        assert(tag_shas.any? { |sha| !git.activity.commit_tokens.include?(sha) })
      end
    end

    it 'must return repository tags' do
      with_git_repository('git') do |git|
        assert_equal git.activity.tags,
                     [['v1.0.0', 'b6e9220c3cabe53a4ed7f32952aeaeb8a822603d', Time.parse('2016-07-31T07:58:30+05:30')],
                      ['v1.1.0-lw', '2e9366dd7a786fdb35f211fff1c8ea05c51968b1',
                       Time.parse('2006-06-11T11:34:17-07:00')],
                      ['v2.1.0', '1df547800dcd168e589bb9b26b4039bff3a7f7e4', Time.parse('2006-07-14T16:07:15-07:00')]]
      end
    end

    it 'must reference valid commits' do
      with_git_repository('git') do |git|
        tag_shas = git.activity.tags.map { |list| list[1] }
        assert(tag_shas.all? { |sha| git.activity.commit_tokens.include?(sha) })
      end
    end

    it 'must be empty for repository with no tags' do
      with_git_repository('git_walk') do |git|
        assert_empty git.activity.tags
      end
    end

    it 'must work for a tag named master' do
      with_git_repository('git_with_master_tag') do |git|
        assert_equal git.activity.tags, [['master', '4e95717ac8cff8cdb10d83398d3ac667a2cca341',
                                          Time.parse('2018-02-01T12:56:48+0530')]]
      end
    end
  end

  it 'must return correct head' do
    with_git_repository('git') do |git|
      assert git.status.exist?
      assert_equal git.activity.head_token, 'a2690f4471a0852723f0f0e95d97f7f1f3981639'
      assert_equal git.activity.head.token, 'a2690f4471a0852723f0f0e95d97f7f1f3981639'
      assert git.activity.head.diffs.any?
    end
  end

  it 'head_token must work with invalid encoding' do
    with_git_repository('git_with_invalid_encoding') do |git|
      git.activity.head_token
    end
  end

  it 'commit_count' do
    with_git_repository('git') do |git|
      assert_equal git.activity.commit_count, 5
      assert_equal git.activity.commit_count(after: 'b6e9220c3cabe53a4ed7f32952aeaeb8a822603d'), 3
      assert_equal git.activity.commit_count(after: '1df547800dcd168e589bb9b26b4039bff3a7f7e4'), 1
    end
  end

  it 'commit_tokens' do
    with_git_repository('git') do |git|
      assert_equal git.activity.commit_tokens, %w[089c527c61235bd0793c49109b5bd34d439848c6
                                                  b6e9220c3cabe53a4ed7f32952aeaeb8a822603d
                                                  2e9366dd7a786fdb35f211fff1c8ea05c51968b1
                                                  1df547800dcd168e589bb9b26b4039bff3a7f7e4
                                                  a2690f4471a0852723f0f0e95d97f7f1f3981639]

      assert_equal git.activity.commit_tokens(after: '2e9366dd7a786fdb35f211fff1c8ea05c51968b1'),
                   %w[1df547800dcd168e589bb9b26b4039bff3a7f7e4 a2690f4471a0852723f0f0e95d97f7f1f3981639]

      assert_empty git.activity.commit_tokens(after: 'a2690f4471a0852723f0f0e95d97f7f1f3981639')
    end
  end

  it 'commits' do
    with_git_repository('git') do |git|
      assert_equal git.activity.commits.collect(&:token), %w[089c527c61235bd0793c49109b5bd34d439848c6
                                                             b6e9220c3cabe53a4ed7f32952aeaeb8a822603d
                                                             2e9366dd7a786fdb35f211fff1c8ea05c51968b1
                                                             1df547800dcd168e589bb9b26b4039bff3a7f7e4
                                                             a2690f4471a0852723f0f0e95d97f7f1f3981639]

      assert_equal git.activity.commits(after: '2e9366dd7a786fdb35f211fff1c8ea05c51968b1').collect(&:token),
                   %w[1df547800dcd168e589bb9b26b4039bff3a7f7e4 a2690f4471a0852723f0f0e95d97f7f1f3981639]

      assert_empty git.activity.commits(after: 'a2690f4471a0852723f0f0e95d97f7f1f3981639')
    end
  end

  it 'commits for branch' do
    with_git_repository('git', 'develop') do |git|
      assert_equal git.activity.commits.map(&:token), %w[089c527c61235bd0793c49109b5bd34d439848c6
                                                         b6e9220c3cabe53a4ed7f32952aeaeb8a822603d
                                                         2e9366dd7a786fdb35f211fff1c8ea05c51968b1
                                                         b4046b9a80fead62fa949232f2b87b0cb78fffcc]

      assert_equal git.activity.commits(after: '2e9366dd7a786fdb35f211fff1c8ea05c51968b1')
                      .map(&:token), ['b4046b9a80fead62fa949232f2b87b0cb78fffcc']

      assert_empty git.activity.commits(after: 'b4046b9a80fead62fa949232f2b87b0cb78fffcc')
    end
  end

  it 'wont track submodule commits and diffs' do
    with_git_repository('git_with_submodules') do |git|
      submodule_commits = %w[240375de181498b9a34d4bd328f2c87d2ade79f9
                             b6a80291e49dc540bb78526f9b1aab1123c9fb0e]

      assert_empty(git.activity.commit_tokens & submodule_commits)

      diffs = git.activity.commits.map(&:diffs).reject(&:empty?).flatten
      assert_equal diffs.map(&:path), ['A']
      assert_equal diffs.map(&:sha1), ['f70f10e4db19068f79bc43844b49f3eece45c4e8']
    end
  end

  it 'commit_count for trunk commits' do
    with_git_repository('git_dupe_delete') do |git|
      assert_equal git.activity.commit_count(trunk_only: false), 4
      assert_equal git.activity.commit_count(trunk_only: true), 3
    end
  end

  it 'commit tokens for trunk commits' do
    with_git_repository('git_dupe_delete') do |git|
      assert_equal git.activity.commit_tokens(trunk_only: false),
                   ['a0a2b8623941562031a7d7f95d984feb4a2d719c', 'ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                    '6126337d2497806528fd8657181d5d4afadd72a4', # On branch
                    '41c4b1044ebffc968d363e5f5e883134e624f846']

      assert_equal git.activity.commit_tokens(trunk_only: true),
                   ['a0a2b8623941562031a7d7f95d984feb4a2d719c', 'ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                    # '6126337d2497806528fd8657181d5d4afadd72a4' # On branch
                    '41c4b1044ebffc968d363e5f5e883134e624f846']
    end
  end

  it 'commit tokens for trunk commits using after' do
    with_git_repository('git_dupe_delete') do |git|
      assert_equal git.activity.commit_tokens(after: 'a0a2b8623941562031a7d7f95d984feb4a2d719c',
                                              trunk_only: true), %w[ad6bb43112706c462e53a9a8a8cd3b05f8e9260f
                                                                    41c4b1044ebffc968d363e5f5e883134e624f846]

      # All trunk commit_tokens, with :after == HEAD
      assert_empty git.activity.commit_tokens(after: '41c4b1044ebffc968d363e5f5e883134e624f846',
                                              trunk_only: true)
    end
  end

  it 'split renamed file diff into add and delete diffs' do
    # `git mv foo bar` results in a single R diff. Split it into A & D diffs.
    with_git_repository('git_with_mv') do |git|
      r_commit = git.activity.commits[-2]
      assert_equal r_commit.message.strip, 'Ran: git mv foo bar'
      assert_equal r_commit.diffs.map(&:action), %w[D A]
      assert_equal r_commit.diffs.map(&:path), %w[foo bar]

      r_commit = git.activity.commits.last
      assert_equal r_commit.message.strip, 'Ran: echo B >> bar; mv bar rab'
      assert_equal r_commit.diffs.map(&:action), %w[D A]
      assert_equal r_commit.diffs.map(&:path), %w[bar rab]
    end
  end

  it 'trunk only commits' do
    with_git_repository('git_dupe_delete') do |git|
      assert_equal git.activity.commits(trunk_only: true).collect(&:token),
                   ['a0a2b8623941562031a7d7f95d984feb4a2d719c', 'ad6bb43112706c462e53a9a8a8cd3b05f8e9260f',
                    # on a branch, hence excluded.
                    # '6126337d2497806528fd8657181d5d4afadd72a4',
                    '41c4b1044ebffc968d363e5f5e883134e624f846']
    end
  end

  # In rare cases, a merge commit's resulting tree is identical to its first parent's tree.
  # I believe this is a result of developer trickery, and not a common situation.
  #
  # When this happens, `git whatchanged` will omit the changes relative to the first parent,
  # and instead output only the changes relative to the second parent.
  #
  # Our commit parser became confused by this, assuming that these changes relative to the
  # second parent were in fact the missing changes relative to the first.
  #
  # This is bug OTWO-623. This test confirms the fix.
  it 'verbose commit with null merge' do
    with_git_repository('git_with_null_merge') do |git|
      c = git.activity.verbose_commit('d3bd0bedbf4b197b2c4eb827e1ec4c35b834482f')
      # This commit's tree is identical to its parent's. Thus it should contain no diffs.
      assert_equal c.diffs, []
    end
  end

  it 'each commit with null merge' do
    with_git_repository('git_with_null_merge') do |git|
      git.activity.each_commit do |c|
        assert_equal c.diffs, [] if c.token == 'd3bd0bedbf4b197b2c4eb827e1ec4c35b834482f'
      end
    end
  end

  it 'verbose_commit must have valid encoding' do
    with_git_repository('git_with_invalid_encoding') do |git|
      assert git.activity.verbose_commit('8d03f4ea64fcd10966fb3773a212b141ada619e1').message.valid_encoding?
    end
  end

  it 'safe_open_log_file must return text with valid encoding' do
    with_git_repository('git_with_invalid_encoding') do |git|
      git.activity.send(:safe_open_log_file) do |io|
        assert_equal io.read.valid_encoding?, true
      end
    end
  end

  it 'commit count when there is a tag named master' do
    with_git_repository('git_with_master_tag') do |git|
      assert_equal git.activity.commit_count, 3
    end
  end

  it 'commit tokens when there is a tag named master' do
    with_git_repository('git_with_master_tag') do |git|
      assert_equal git.activity.commit_tokens, %w[57b2bd30b7bae970cb3b374a0c05fd6ec3088ebf
                                                  4e95717ac8cff8cdb10d83398d3ac667a2cca341
                                                  34b8a99e6e5dd39bc36893f71e0ab1685668731f]
    end
  end

  it 'must cat file correctly' do
    with_git_repository('git') do |core|
      diff = OhlohScm::Diff.new(sha1: '4c734ad53b272c9b3d719f214372ac497ff6c068')
      assert_equal core.activity.cat_file(nil, diff), <<-EXPECTED.gsub(/^ {8}/, '')
        /* Hello, World! */
        #include <stdio.h>
        main()
        {
        	printf("Hello, World!\\n");
        }
      EXPECTED
    end
  end

  describe 'commit_tokens' do
    it 'must return commit tokens within range' do
      with_git_repository('git_walk') do |git|
        commit_tokens = CommitTokensHelper.new(git, commit_labels)
        # Full history to a commit
        assert_equal commit_tokens.between(nil, :A), %i[A]
        assert_equal commit_tokens.between(nil, :B), %i[A B]
        assert_equal commit_tokens.between(nil, :C), %i[A B G H C]
        assert_equal commit_tokens.between(nil, :D), %i[A B G H C I D]
        assert_equal commit_tokens.between(nil, :G), %i[A G]
        assert_equal commit_tokens.between(nil, :H), %i[A G H]
        assert_equal commit_tokens.between(nil, :I), %i[A G H I]
        assert_equal commit_tokens.between(nil, :J), %i[A G H I J]

        # Limited history from one commit to another
        assert_empty commit_tokens.between(:A, :A)
        assert_equal commit_tokens.between(:A, :B), %i[B]
        assert_equal commit_tokens.between(:A, :C), %i[B G H C]
        assert_equal commit_tokens.between(:A, :D), %i[B G H C I D]
        assert_equal commit_tokens.between(:B, :D), %i[G H C I D]
        assert_equal commit_tokens.between(:C, :D), %i[I D]
        assert_equal commit_tokens.between(:G, :J), %i[H I J]
      end
    end

    it 'must return trunk commit tokens within range' do
      with_git_repository('git_walk') do |git|
        commit_tokens = CommitTokensHelper.new(git, commit_labels, trunk_only: true)
        # Full history to a commit
        assert_equal commit_tokens.between(nil, :A), %i[A]
        assert_equal commit_tokens.between(nil, :B), %i[A B]
        assert_equal commit_tokens.between(nil, :C), %i[A B C]
        assert_equal commit_tokens.between(nil, :D), %i[A B C D]

        # Limited history from one commit to another
        assert_empty commit_tokens.between(:A, :A)
        assert_equal commit_tokens.between(:A, :B), %i[B]
        assert_equal commit_tokens.between(:A, :C), %i[B C]
        assert_equal commit_tokens.between(:A, :D), %i[B C D]
        assert_equal commit_tokens.between(:B, :D), %i[C D]
        assert_equal commit_tokens.between(:C, :D), %i[D]
      end
    end

    it 'must commit all changes in the working directory' do
      tmpdir do |dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, branch_name: 'master', url: dir)

        core.activity.send(:init_db)
        refute core.activity.send(:anything_to_commit?)

        File.open(File.join(dir, 'README'), 'w') {}
        assert core.activity.send(:anything_to_commit?)

        c = OhlohScm::Commit.new
        c.author_name = 'John Q. Developer'
        c.message = 'Initial checkin.'
        core.activity.commit_all(c)
        refute core.activity.send(:anything_to_commit?)

        assert_equal core.activity.commits.size, 1

        assert_equal core.activity.commits.first.author_name, c.author_name
        # Depending on version of Git used, we may or may not have trailing \n.
        # We don't really care, so just compare the stripped versions.
        assert_equal core.activity.commits.first.message.strip, c.message.strip

        assert_equal ['.gitignore', 'README'], core.activity.commits.first.diffs.collect(&:path).sort
      end
    end

    it 'must test that no token returns nil' do
      tmpdir do |dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, branch_name: 'master', url: dir)
        refute core.activity.read_token
        core.activity.send(:init_db)
        refute core.activity.read_token
      end
    end

    it 'must test write and read token' do
      tmpdir do |dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, branch_name: 'master', url: dir)
        core.activity.send(:init_db)
        core.activity.send(:write_token, 'FOO')
        refute core.activity.read_token # Token not valid until committed
        core.activity.commit_all(OhlohScm::Commit.new)
        assert_equal core.activity.read_token, 'FOO'
      end
    end

    it 'must test that commit_all includes write token' do
      tmpdir do |dir|
        core = OhlohScm::Factory.get_core(scm_type: :git, branch_name: 'master', url: dir)
        core.activity.send(:init_db)
        c = OhlohScm::Commit.new
        c.token = 'BAR'
        core.activity.commit_all(c)
        assert_equal c.token, core.activity.read_token
      end
    end

    it 'must test read_token encoding' do
      with_git_repository('git_with_invalid_encoding') do |core|
        core.activity.read_token
      end
    end

    def commit_labels
      { A: '886b62459ef1ffd01a908979d4d56776e0c5ecb2',
        B: 'db77c232f01f7a649dd3a2216199a29cf98389b7',
        C: 'f264fb40c340a415b305ac1f0b8f12502aa2788f',
        D: '57fedf267adc31b1403f700cc568fe4ca7975a6b',
        G: '97b80cb9743948cf302b6e21571ff40721a04c8d',
        H: 'b8291f0e89567de3f691afc9b87a5f1908a6f3ea',
        I: 'd067161caae2eeedbd74976aeff5c4d8f1ccc946',
        J: 'b49aeaec003cf8afb18152cd9e292816776eecd6' }
    end
  end
end
