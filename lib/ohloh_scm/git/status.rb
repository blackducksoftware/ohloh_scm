# frozen_string_literal: true

module OhlohScm
  module Git
    class Status < OhlohScm::Status
      def branch?(name = scm.branch_name)
        return unless scm_dir_exist?

        activity.branches.include?(name)
      end

      def default_branch
        return scm.branch_name_or_default unless exist?

        name = run("git remote show '#{scm.url}' | grep 'HEAD branch' | awk '{print $3}'").strip
        name.to_s.empty? ? scm.branch_name_or_default : name
      end
    end
  end
end
