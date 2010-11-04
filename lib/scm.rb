module Scm
end

require 'rbconfig'

$: << File.join(File.dirname(__FILE__),"..")

require 'lib/scm/shellout'
require 'lib/scm/scratch_dir'
require 'lib/scm/commit'
require 'lib/scm/diff'

require 'lib/scm/adapters/abstract_adapter'
require 'lib/scm/adapters/cvs_adapter'
require 'lib/scm/adapters/svn_adapter'
require 'lib/scm/adapters/svn_chain_adapter'
require 'lib/scm/adapters/git_adapter'
require 'lib/scm/adapters/hg_adapter'
require 'lib/scm/adapters/hglib_adapter'
require 'lib/scm/adapters/bzr_adapter'
require 'lib/scm/adapters/bzrlib_adapter'
require 'lib/scm/adapters/darcs_adapter'
require 'lib/scm/adapters/factory'

require 'lib/scm/parsers/parser'
require 'lib/scm/parsers/branch_number'
require 'lib/scm/parsers/cvs_parser'
require 'lib/scm/parsers/svn_parser'
require 'lib/scm/parsers/svn_xml_parser'
require 'lib/scm/parsers/git_parser'
require 'lib/scm/parsers/git_styled_parser'
require 'lib/scm/parsers/hg_parser'
require 'lib/scm/parsers/hg_styled_parser'
require 'lib/scm/parsers/bzr_xml_parser'
require 'lib/scm/parsers/bzr_parser'
require 'lib/scm/parsers/darcs_parser'

require 'lib/scm/parsers/array_writer'
require 'lib/scm/parsers/xml_writer'
require 'lib/scm/parsers/human_writer'
