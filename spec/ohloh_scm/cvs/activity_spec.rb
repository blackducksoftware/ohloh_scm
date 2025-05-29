# frozen_string_literal: true

require 'spec_helper'

describe 'Cvs::Activity' do
  it 'must return the host' do
    activity = get_core(:cvs, url: ':ext:anonymous:@moodle.cvs.sourceforge.net:/cvsroot/moodle',
                              branch_name: 'contrib').activity
   assert_equal  activity.send(:host), 'moodle.cvs.sourceforge.net'
  end

  it 'must return the protocol' do
    activity = get_core(:cvs, url: ':pserver:foo:@foo.com:/cvsroot/a', branch_name: 'b').activity
    assert_equal activity.send(:protocol), :pserver

    activity = get_core(:cvs, url: ':ext:foo:@foo.com:/cvsroot/a', branch_name: 'b').activity
    assert_equal activity.send(:protocol), :ext

    activity = get_core(:cvs, url: ':pserver:ext:@foo.com:/cvsroot/a', branch_name: 'b').activity
    assert_equal activity.send(:protocol), :pserver
  end

  it 'must test tags' do
    with_cvs_repository('cvs', 'simple') do |cvs|
      assert_equal cvs.activity.tags, [['simple_release_tag', '1.1.1.1'], ['simple_vendor_tag', '1.1.1']]
    end
  end

  it 'must test export_tag' do
    with_cvs_repository('cvs', 'simple') do |cvs|
      Dir.mktmpdir('oh_scm_tag_') do |dir|
        cvs.activity.export_tag(dir, 'simple_release_tag')
        assert_equal Dir.entries(dir).sort, ['.', '..', 'foo.rb']
      end
    end
  end

  it 'must test commits' do
    with_cvs_repository('cvs', 'simple') do |cvs|
      assert_equal cvs.activity.commits.collect(&:token), ['2006-06-29 16:21:07',
                                                        '2006-06-29 18:14:47',
                                                        '2006-06-29 18:45:29',
                                                        '2006-06-29 18:48:54',
                                                        '2006-06-29 18:52:23']

      # Make sure we are date format agnostic (2008/01/01 is the same as 2008-01-01)
      assert_equal cvs.activity.commits(after: '2006/06/29 18:45:29').collect(&:token), 
      ['2006-06-29 18:48:54', '2006-06-29 18:52:23']

      assert_equal cvs.activity.commits(after: '2006-06-29 18:45:29')
         .collect(&:token), ['2006-06-29 18:48:54',
                                       '2006-06-29 18:52:23']

      assert_empty cvs.activity.commits(after: '2006/06/29 18:52:23').collect(&:token)
    end
  end

  it 'must correctly convert commits to git' do
    with_cvs_repository('cvs', 'simple') do |cvs|
      tmpdir do |tmp_dir|
        git_core = OhlohScm::Factory.get_core(url: tmp_dir, branch_name: 'master')
        git_core.scm.pull(cvs.scm, TestCallback.new)
        utc_dates = ['2006-06-29 16:21:07 UTC', '2006-06-29 18:14:47 UTC',
                     '2006-06-29 18:45:29 UTC', '2006-06-29 18:48:54 UTC',
                     '2006-06-29 18:52:23 UTC']
        assert_equal git_core.activity.commits.map(&:author_date).map(&:to_s), utc_dates
      end
    end
  end

  it 'must test commits sets scm' do
    with_cvs_repository('cvs', 'simple') do |cvs|
      cvs.activity.commits.each do |c|
        assert_equal cvs.activity.scm, c.scm
      end
    end
  end

  it 'must test open log file encoding' do
    with_cvs_repository('cvs', 'invalid_utf8') do |cvs|
      cvs.activity.send(:open_log_file) do |io|
        assert_equal io.read.valid_encoding?, true
      end
    end
  end

  it 'commits must work with invalid_encoding' do
    with_cvs_repository('cvs', 'invalid_utf8') do |cvs|
      cvs.activity.commits
    end
  end
end
