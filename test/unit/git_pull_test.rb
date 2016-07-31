require_relative '../test_helper'

module OhlohScm::Adapters
	class GitPullTest < OhlohScm::Test

		def test_basic_pull
			with_git_repository('git') do |src|
				OhlohScm::ScratchDir.new do |dest_dir|

					dest = GitAdapter.new(:url => dest_dir).normalize
					assert !dest.exist?

					dest.pull(src)
					assert dest.exist?

					assert_equal src.log, dest.log
				end
			end
		end

	end
end
