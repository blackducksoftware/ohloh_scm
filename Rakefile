require 'rake'
require 'rake/clean'
require 'rake/testtask'

Rake::TestTask.new :unit_tests do |t|
	t.test_files = FileList[File.dirname(__FILE__) + '/test/unit/**/*_test.rb']
end

task :default => :unit_tests

