# frozen_string_literal: true

using OhlohScm::StringExtensions

module OhlohScm
  class Core
    attr_reader :scm, :activity, :status

    def initialize(scm_type, url, branch_name, username, password)
      scm_opts = { core: self, url: url, branch_name: branch_name,
                   username: username, password: password }
      scm_class_name = scm_type.to_s.camelize

      @scm = OhlohScm.const_get(scm_class_name)::Scm.new(scm_opts)
      @activity = OhlohScm.const_get(scm_class_name)::Activity.new(self)
      @status = OhlohScm.const_get(scm_class_name)::Status.new(self)
    end
  end
end
