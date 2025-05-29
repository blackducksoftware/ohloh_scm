require 'spec_helper'
require 'mocha'

describe 'Svn::Activity' do
  describe 'cat' do
    let(:commit_1) { OhlohScm::Commit.new(token: 1) }
    let(:hello_diff) { OhlohScm::Diff.new(path: 'helloworld.c') }

    it 'must export data correctly' do
      with_svn_repository('svn') do |svn|
        tmpdir do |dir|
          svn.activity.export(dir)
          assert_equal Dir.entries(dir).sort, %w[. .. branches tags trunk]
        end
      end
    end

    it 'must export tags correctly' do
      with_svn_repository('svn', 'trunk') do |svn|
        tmpdir do |svn_working_folder|
          tmpdir('oh_scm_out_dir_') do |dir|
            root_path = svn.activity.root
            folder_name = root_path.slice(/[^\/]+\/?\Z/)
            cmd = "cd #{svn_working_folder} && svn co #{root_path} && cd #{folder_name}"\
                  " && mkdir -p #{root_path.gsub(/^file:../, '')}/db/transactions"\
                  " && svn copy trunk tags/2.0 && svn commit -m 'v2.0' && svn update"
            svn.activity.send :run, cmd

            svn.activity.export_tag(dir, '2.0')

            assert_equal Dir.entries(dir).sort, %w[. .. COPYING README helloworld.c makefile]
          end
        end
      end
    end

    it 'must get tags correctly' do
      with_svn_repository('svn', 'trunk') do |svn|
        tmpdir do |svn_working_folder|
          root_path = svn.activity.root
          folder_name = root_path.slice(/[^\/]+\/?\Z/)
          cmd = "cd #{svn_working_folder} && svn co #{root_path} && cd #{folder_name}"\
                " && mkdir -p #{root_path.gsub(/^file:../, '')}/db/transactions"\
                " && svn copy trunk tags/2.0 && svn commit -m 'v2.0' && svn update"
          svn.activity.send :run, cmd

          assert_equal svn.activity.tags.first[0..1], ['2.0', '6']
          # Avoid millisecond comparision.
          assert_equal svn.activity.tags.first[-1].strftime('%F %R'), Time.now.utc.strftime('%F %R')
        end
      end
    end
  end
end
