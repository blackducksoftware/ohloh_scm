# frozen_string_literal: true

module RepositoryHelper
  %w[svn git_svn cvs hg bzr].each do |scm_type|
    define_method("with_#{scm_type}_repository") do |name, branch_name = nil, &block|
      with_repository(scm_type, name, branch_name) { |core| block.call(core) }
    end
  end

  def with_git_repository(name, branch_name = 'master', &block)
    with_repository('git', name, branch_name) { |core| block.call(core) }
  end

  private

  def with_repository(scm_type, name, branch_name = nil)
    source_path = get_fixture_folder_path(name)
    Dir.mktmpdir('oh_scm_fixture_') do |dir_path|
      setup_repository_archive(source_path, dir_path)
      path_prefix = scm_type == 'svn' ? 'file://' : ''
      yield OhlohScm::Factory.get_core(scm_type: scm_type, url: "#{path_prefix}#{File.join(dir_path, name)}",
                                       branch_name: branch_name)
    end
  end

  def setup_repository_archive(source_path, dir_path)
    if Dir.exist?(source_path)
      `cp -R #{source_path} #{dir_path}`
    elsif File.exist?("#{source_path}.tgz")
      `tar xzf #{source_path}.tgz --directory #{dir_path}`
    else
      raise "Repository archive #{source_path} not found."
    end
  end

  def get_fixture_folder_path(name)
    fixture_dir = File.expand_path('../scm_fixtures', __dir__)
    File.join(fixture_dir, name)
  end
end
