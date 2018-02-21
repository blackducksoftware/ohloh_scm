module OhlohScm::Adapters
  class AbstractAdapter

    def is_merge_commit?(commit)
      false
    end

    def tags
      []
    end

    def escape_single_quote(str)
      str.to_s.gsub("'", "'\''")
    end
  end
end
