# frozen_string_literal: true

require 'timeout'

module OhlohScm
  class Validation
    include OhlohScm::System
    extend Forwardable
    def_delegators :@core, :scm, :activity, :status
    attr_reader :errors

    def initialize(core)
      @core = core
    end

    def validate
      validate_attributes
      Timeout.timeout(timeout_interval) { validate_server_connection } if @errors.none?
    end

    private

    def validate_server_connection; end

    def validate_attributes
      @errors = []
      @errors << url_errors
      @errors << branch_name_errors
      @errors << username_errors if scm.username
      @errors << password_errors if scm.password
      @errors.compact!
    end

    # rubocop:disable Metrics/AbcSize
    def url_errors
      error = if scm.url.nil? || scm.url.empty?
                "The URL can't be blank."
              elsif scm.url.length > 120
                'The URL must not be longer than 120 characters.'
              elsif !scm.url.match?(public_url_regex)
                'The URL does not appear to be a valid server connection string.'
              end

      [:url, error] if error
    end
    # rubocop:enable Metrics/AbcSize

    def branch_name_errors
      if scm.branch_name.to_s.empty?
        [:branch_name, 'Invalid Branch Name.']
      elsif scm.branch_name.length > 80
        [:branch_name, 'The branch name must not be longer than 80 characters.']
      elsif !scm.branch_name.match?(/^[\w^\-\+\.\/\ ]+$/)
        [:branch_name, "The branch name may contain only letters, numbers, \
           spaces, and the special characters '_', '-', '+', '/', '^', and '.'"]
      end
    end

    def username_errors
      if scm.username.length > 32
        [:username, 'The username must not be longer than 32 characters.']
      elsif !scm.username.match?(/^\w*$/)
        [:username, 'The username may contain only A-Z, a-z, 0-9, and underscore (_)']
      end
    end

    def password_errors
      if scm.password.length > 32
        [:password, 'The password must not be longer than 32 characters.']
      elsif !scm.password.match?(/^[\w!@\#$%^&*\(\)\{\}\[\]\;\?\|\+\-\=]*$/)
        [:password, 'The password contains illegal characters']
      end
    end

    def timeout_interval
      ENV['SCM_URL_VALIDATION_TIMEOUT']&.to_i || 60
    end

    def public_url_regex; end
  end
end
