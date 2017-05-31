# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'ohloh_scm/version'

Gem::Specification.new do |gem|
  gem.name          = 'ohloh_scm'
  gem.version       = OhlohScm::Version::STRING
  gem.authors       = ["BlackDuck Software"]
  gem.email         = ["info@openhub.net"]
  gem.summary       = %[Source Control Management]
  gem.description   = %[The Ohloh source control management library for interacting with Git, SVN, CVS, Hg and Bzr repositories.]
  gem.homepage      = %[https://github.com/blackducksw/ohloh_scm/]
  gem.license       = %[GPL v2.0]

  gem.files         = `git ls-files -z`.split("\x0")
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w(lib)

  gem.add_runtime_dependency 'test-unit'
  gem.add_runtime_dependency 'posix-spawn', '~> 0.3'
  gem.add_runtime_dependency 'nokogiri', '~> 1.6', '>= 1.6.8'
end
