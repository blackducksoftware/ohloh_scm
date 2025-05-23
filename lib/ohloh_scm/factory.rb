# frozen_string_literal: true

module OhlohScm
  module Factory
    module_function

    def get_core(url:, scm_type: :git, branch_name: nil, username: nil, password: nil)
      OhlohScm::Core.new(scm_type, url, branch_name, username, password)
    end
  end
end
