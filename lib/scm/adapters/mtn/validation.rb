module Scm::Adapters
  class MtnAdapter < AbstractAdapter

    def self.public_url_regex
      /^(mtn|ssh):\/\/(\w+@)?[A-Za-z0-9_\-\.]+(:\d+)?\/[A-Za-z0-9_\-\.\/\~\+]*(\?[A-Za-z0-9_\-\.\/\~\+]*)+$/
    end

    def validate_server_connection
      return unless valid?
      @errors << [:failed, "The server did not respond to the 'mtn' command. Is the URL correct? "] unless self.remote_exist?
    end

  end
end
