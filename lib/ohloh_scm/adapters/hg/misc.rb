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
      tag_strings.map do |tag_string|
        parsed_str = tag_string.split(' ')
        rev_number_and_hash = parsed_str.pop
        tag_name = parsed_str.join(' ')
        rev = rev_number_and_hash.slice(/\A\d+/)
        time_string = run("cd '#{ path }' && hg log -r #{ rev } | grep 'date:' | sed 's/date://'")
        [tag_name, rev, Time.parse(time_string)]
      end
    end
	end
end
