# frozen_string_literal: true

module OhlohScm
  module Cvs
    class Status < OhlohScm::Status
      def lock?
        run "timeout 2m cvsnt -q -d #{scm.url} rlog '#{scm.branch_name}'"
        false
      rescue StandardError => e
        raise 'CVS lock has been found' if /waiting for.*lock in/.match?(e.message)
      end
    end
  end
end
