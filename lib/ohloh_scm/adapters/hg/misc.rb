module OhlohScm::Adapters
	class HgAdapter < AbstractAdapter
		def exist?
			begin
				!!(head_token)
			rescue
				logger.debug { $! }
				false
			end
		end

		def ls_tree(token)
			run("cd '#{path}' && hg manifest -r #{token} | #{ string_encoder }").split("\n")
		end

		def export(dest_dir, token='tip')
			run("cd '#{path}' && hg archive -r #{token} '#{dest_dir}'")
			# Hg leaves a little cookie crumb in the export directory. Remove it.
			File.delete(File.join(dest_dir, '.hg_archival.txt')) if File.exist?(File.join(dest_dir, '.hg_archival.txt'))
		end

    def tags
      tag_strings = run("cd '#{path}' && hg tags").split(/\n/)
      tags_and_revs = tag_strings.map do |tag_string|
        tag_name, rev_number_and_hash = tag_string.split(/\s+/)
        rev_number = rev_number_and_hash.slice(/\A\d+/)
        [tag_name, rev_number]
      end

      Hash[tags_and_revs]
    end
	end
end
