# frozen_string_literal: true

module OhlohScm
  module Factory
    module_function

    def get_core(opts = {})
      scm_type = opts.fetch(:scm_type, :git)
      url = opts.fetch(:url) { raise ArgumentError, 'URL is required' }
      branch_name = opts[:branch_name]
      username = opts[:username]
      password = opts[:password]

      OhlohScm::Core.new(scm_type, url, branch_name, username, password)
    end
  end
end
