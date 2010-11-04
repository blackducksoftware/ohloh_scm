module OhlohScm::Parsers
	class CommandLineTest < OhlohScm::Test
		def test_cvs_from_file
			result = `#{File.dirname(__FILE__) + '/../../bin/ohlog'} --xml --cvs #{DATA_DIR + '/basic.rlog'}`
			assert_equal 0, $?
			assert_buffers_equal File.read(DATA_DIR + '/basic.ohlog'), result
		end

		def test_cvs_from_pipe
			result = `cat #{DATA_DIR + '/basic.rlog'} | #{File.dirname(__FILE__) + '/../../bin/ohlog'} --xml --cvs`
			assert_equal 0, $?
			assert_buffers_equal File.read(DATA_DIR + '/basic.ohlog'), result
		end

		def test_svn_from_file
			result = `#{File.dirname(__FILE__) + '/../../bin/ohlog'} --xml --svn #{DATA_DIR + '/simple.svn_log'}`
			assert_equal 0, $?
			assert_buffers_equal File.read(DATA_DIR + '/simple.ohlog'), result
		end

		def test_svn_xml_from_file
			result = `#{File.dirname(__FILE__) + '/../../bin/ohlog'} --xml --svn-xml #{DATA_DIR + '/simple.svn_xml_log'}`
			assert_equal 0, $?
			assert_buffers_equal File.read(DATA_DIR + '/simple.ohlog'), result
		end

		def test_hg_from_file
		end

		#def test_darcs_from_file
		#end

		def test_help
			result = `#{File.dirname(__FILE__) + '/../../bin/ohlog'} -?`
			assert_equal 0, $?
			assert result =~ /Examples:/
		end
	end
end
