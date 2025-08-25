# frozen_string_literal: true

$LOAD_PATH << File.expand_path('lib', __dir__)
require 'ohloh_scm/version'

Gem::Specification.new do |gem|
  gem.name          = 'ohloh_scm'
  gem.version       = OhlohScm::Version::STRING
  gem.authors       = ['OpenHub Team at Synopsys']
  gem.email         = ['info@openhub.net']
  gem.summary       = 'Source Control Management'
  gem.description   = 'The OpenHub source control management library for \
                       interacting with Git, SVN, CVS, Hg and Bzr repositories.'
  gem.homepage      = 'https://github.com/blackducksoftware/ohloh_scm/'
  gem.license       = 'GPL-2.0'

  gem.files         = `git ls-files -z`.split("\x0")
  gem.require_paths = %w[lib]
  gem.required_ruby_version = '>= 3.0.0'
  gem.post_install_message = "Ohloh SCM is depending on Git #{OhlohScm::Version::GIT}, " \
                             "SVN #{OhlohScm::Version::SVN}, CVSNT #{OhlohScm::Version::CVSNT}, " \
                             "Mercurial #{OhlohScm::Version::HG} and Bazaar " \
                             "#{OhlohScm::Version::BZR}. If the installed version is different, " \
                             'Ohloh SCM may not operate as expected.'
end
