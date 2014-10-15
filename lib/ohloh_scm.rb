module OhlohScm
end

#require 'rbconfig'

#$: << File.join(File.dirname(__FILE__),"..")

require_relative 'ohloh_scm/shellout'
require_relative 'ohloh_scm/scratch_dir'
require_relative 'ohloh_scm/commit'
require_relative 'ohloh_scm/diff'

require_relative 'ohloh_scm/adapters/abstract_adapter'
require_relative 'ohloh_scm/adapters/cvs_adapter'
require_relative 'ohloh_scm/adapters/svn_adapter'
require_relative 'ohloh_scm/adapters/svn_chain_adapter'
require_relative 'ohloh_scm/adapters/git_adapter'
require_relative 'ohloh_scm/adapters/hg_adapter'
require_relative 'ohloh_scm/adapters/hglib_adapter'
require_relative 'ohloh_scm/adapters/bzr_adapter'
require_relative 'ohloh_scm/adapters/bzrlib_adapter'
require_relative 'ohloh_scm/adapters/darcs_adapter'
require_relative 'ohloh_scm/adapters/factory'

require_relative 'ohloh_scm/parsers/parser'
require_relative 'ohloh_scm/parsers/branch_number'
require_relative 'ohloh_scm/parsers/cvs_parser'
require_relative 'ohloh_scm/parsers/svn_parser'
require_relative 'ohloh_scm/parsers/svn_xml_parser'
require_relative 'ohloh_scm/parsers/git_parser'
require_relative 'ohloh_scm/parsers/git_styled_parser'
require_relative 'ohloh_scm/parsers/hg_parser'
require_relative 'ohloh_scm/parsers/hg_styled_parser'
require_relative 'ohloh_scm/parsers/bzr_xml_parser'
require_relative 'ohloh_scm/parsers/bzr_parser'
require_relative 'ohloh_scm/parsers/darcs_parser'

require_relative 'ohloh_scm/parsers/array_writer'
require_relative 'ohloh_scm/parsers/xml_writer'
require_relative 'ohloh_scm/parsers/human_writer'
