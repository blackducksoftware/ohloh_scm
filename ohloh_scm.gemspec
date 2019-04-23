# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'ohloh_scm/version'

Gem::Specification.new do |gem|
  gem.name          = 'oh_scm'
  gem.version       = OhlohScm::Version::STRING
  gem.authors       = ['OpenHub Team at Synopsys']
  gem.email         = ['info@openhub.net']
  gem.summary       = 'Source Control Management'
  gem.description   = 'The OpenHub source control management library for \
                       interacting with Git, SVN, CVS, Hg and Bzr repositories.'
  gem.homepage      = 'https://github.com/blackducksoftware/ohloh_scm/'
  gem.license       = 'GPL-2.0'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.test_files    = gem.files.grep(/^spec\//)
  gem.require_paths = %w[lib]
end
