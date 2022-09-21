# frozen_string_literal: true

module OhlohScm
  module Hg
    class Scm < OhlohScm::Scm
      def pull(remote_scm, callback)
        err_msg = "Cannot pull remote_scm #{remote_scm.inspect}"
        raise ArgumentError, err_msg unless remote_scm.is_a?(Hg::Scm)

        clone_or_fetch(remote_scm, callback)
      end

      def branch_name_or_default
        branch_name || :default
      end

      def vcs_path
        "#{url}/.hg"
      end

      def checkout_files(names)
        pattern = "(#{ names.join('|') })"
        run "cd #{url} && hg revert $(hg manifest | grep -P '#{pattern}')"
      end

      private

      def clone_or_fetch(remote_scm, callback)
        callback.update(0, 1)

        status.exist? ? revert_and_pull(remote_scm) : clone_repository(remote_scm)

        clean_up_disk

        callback.update(1, 1)
      end

      def clone_repository(remote_scm)
        run "rm -rf '#{url}'"
        run "hg clone '#{remote_scm.url}' '#{url}'"
      end

      def revert_and_pull(remote_scm)
        branch_opts = "-r #{remote_scm.branch_name}" if branch_name
        run "cd '#{url}' && hg revert --all && hg pull #{branch_opts} -u -y '#{remote_scm.url}'"
      end

      def clean_up_disk
        return unless FileTest.exist?(url)

        run "cd #{url} && find . -maxdepth 1 -not -name .hg -not -name '*.nfs*' -not -name . -print0"\
              ' | xargs -0 rm -rf --'
      end
    end
  end
end
