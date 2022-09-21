# frozen_string_literal: true

module OhlohScm
  module GitSvn
    class Scm < OhlohScm::Scm
      def initialize(core:, url:, branch_name:, username:, password:)
        super
        @branch_name = branch_name || :master
      end

      def pull(source_scm, callback)
        @source_scm = source_scm
        convert_to_git(callback)
      end

      def accept_ssl_certificate_cmd
        File.expand_path('../../../.bin/accept_svn_ssl_certificate', __dir__)
      end

      def vcs_path
        "#{url}/.git"
      end

      private

      def convert_to_git(callback)
        callback.update(0, 1)
        if FileTest.exist?(git_path)
          accept_certificate_if_prompted
          fetch
        else
          clone
        end

        clean_up_disk
        callback.update(1, 1)
      end

      def git_path
        File.join(url, '/.git')
      end

      def clone
        prepare_dest_dir
        accept_certificate_if_prompted

        cmd = "#{password_prompt} git svn clone --quiet #{username_opts}"\
                " '#{@source_scm.url}' '#{url}'"
        run(cmd)
      end

      def accept_certificate_if_prompted
        # git svn does not support non iteractive and serv-certificate options
        # Permanently accept svn certificate when it prompts
        opts = username_and_password_opts
        run "#{accept_ssl_certificate_cmd} svn info #{opts} '#{@source_scm.url}'"
      end

      def username_and_password_opts
        username = username.to_s.empty? ? '' : "--username #{@source_scm.username}"
        password = password.to_s.empty? ? '' : "--password='#{@source_scm.password}'"
        "#{username} #{password}"
      end

      def password_prompt
        password.to_s.empty? ? '' : "echo #{password} |"
      end

      def username_opts
        username.to_s.empty? ? '' : "--username #{username}"
      end

      def prepare_dest_dir
        FileUtils.mkdir_p(url)
        FileUtils.rm_rf(url)
      end

      def fetch
        cmd = "cd #{url} && git svn fetch"
        run(cmd)
      end

      def clean_up_disk
        return unless  File.exist?(url)
        sleep 1

        run "cd #{url} && find . -maxdepth 1 -not -name .git -not -name '*.nfs*' -not -name . -print0"\
              ' | xargs -0 rm -rf --'
      end
    end
  end
end
