require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/mtn_abstract_test_class'

module Scm::Adapters
  class MtnPushTest < Scm::Adapters::MtnAbstractTest

    def test_push
      init_with_dest_dir do |src, dest_dir|
        local = MtnAdapter.new(:url => File.join(dest_dir,'mtn')).normalize
        # We need a database
        local.database = File.join(dest_dir, 'local.mtn')

        assert !local.exist?

        #We save the url of the working copy
        wc_url = src.url
        distant_url = "file://#{src.database}"
        src.url  = distant_url

        # we get a copy
        puts "Pulling from #{src.database} to #{local.database}"
        local.pull(src)
        assert local.exist?

        # we change the url to point to working copy where logs are possible
        src.url = wc_url
        assert_equal src.commits.first.message, local.commits.first.message
        
        # before pushing in, we need a key
        begin
          src.run "cd #{src.url} && mtn automate generate_key dummykey no_pass"
         rescue
          puts "Ouuppps, we already have a key so we can't create the same. Will do nothing"
        end
          
        # Commit some new code on the original and pull again
        # Use a lua hook to provide the password
        rcfile=File.join(File.join(REPO_DIR, "mtn"), "lua_hooks")
        local.run "cd '#{local.url}' && touch foo && mtn add foo && mtn -k dummykey --rcfile=#{rcfile} commit -m test"
        assert_equal "test", local.commits.first.message
        
        # we must use a distant url to push
        src.url = distant_url

        # we can now push to our origin
        local.push(src)

        # As log can only be asked to wc if don't own a key
        # change our origin to working copy directory
        src.url = wc_url
        assert_equal src.commits.first.message, local.commits.first.message
      end
    end
    
    def test_hostname
      assert !MtnAdapter.new.hostname
      assert !MtnAdapter.new(:url => "http://www.ohloh.net/test").hostname
      assert !MtnAdapter.new(:url => "/Users/robin/foo").hostname
      assert_equal "foo", MtnAdapter.new(:url => 'ssh://foo/bar').hostname
    end

    def test_local
      assert !MtnAdapter.new(:url => "foo:/bar").local? # Assuming your machine is not named "foo" :-)
      assert !MtnAdapter.new(:url => "http://www.ohloh.net/foo").local?
      assert !MtnAdapter.new(:url => "ssh://host/Users/robin/src").local?
      assert MtnAdapter.new(:url => "src").local?
      assert MtnAdapter.new(:url => "/Users/robin/src").local?
#      assert MtnAdapter.new(:url => "file:///Users/robin/src").local?
      assert MtnAdapter.new(:url => "ssh://#{Socket.gethostname}/Users/robin/src").local?
    end

    def test_path
      assert_equal nil, MtnAdapter.new().path
      assert_equal nil, MtnAdapter.new(:url => "http://ohloh.net/foo").path
      assert_equal nil, MtnAdapter.new(:url => "https://ohloh.net/foo").path
      assert_equal "/Users/robin/foo", MtnAdapter.new(:url => "file:///Users/robin/foo").path
      assert_equal "/Users/robin/foo", MtnAdapter.new(:url => "ssh://localhost/Users/robin/foo").path
      assert_equal "/Users/robin/foo", MtnAdapter.new(:url => "/Users/robin/foo").path
    end
  end
end
