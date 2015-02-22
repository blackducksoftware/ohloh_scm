require File.dirname(__FILE__) + '/../test_helper'

module OhlohScm::Adapters
	# Repository darcs_walk has the following structure:
	#
	#    A -> B -> C -> D -> E
	#
	class DarcsRevListTest < OhlohScm::Test

		def test_rev_list
			with_darcs_repository('darcs_walk') do |darcs|
				# Full history to a commit
				assert_equal [:A],                 rev_list_helper(darcs, nil, :A)
				assert_equal [:A, :B],             rev_list_helper(darcs, nil, :B)
				assert_equal [:A, :B, :C, :D, :E], rev_list_helper(darcs, nil, :E)
				assert_equal [:A, :B, :C, :D, :E], rev_list_helper(darcs, nil, nil)

				# # Limited history from one commit to another
				assert_equal [],           rev_list_helper(darcs, :A, :A)
				assert_equal [:B],         rev_list_helper(darcs, :A, :B)
				assert_equal [:B, :C, :D], rev_list_helper(darcs, :A, :D)
			end
		end

		protected

		def rev_list_helper(darcs, from, to)
			to_labels(darcs.commit_tokens(:after => from_label(from), :up_to => from_label(to)))
		end

		def commit_labels
			{ '25b46d61afa639f268c929e6259f1271b7a43d6f' => :A,
				'7a1b8ed05d56b7099a2c16157ec7a947bcab9c9a' => :B,
				'd50ee74be0f34fed3e23ec90346976024de40962' => :C,
				'48dac48b9d5543895c409e81de18ff077f4dc1c3' => :D,
				'3dbdfd7313c96379fd8a3ca4e6ebaf1bd12d46ae' => :E
			}
		end

		def to_label(sha1)
			commit_labels[sha1.to_s]
		end

		def to_labels(sha1s)
			sha1s.collect { |sha1| to_label(sha1) }
		end

		def from_label(l)
			commit_labels.each_pair { |k,v| return k if v.to_s == l.to_s }
			nil
		end
	end
end
