module GenericHelper
  def tmpdir(prefix = 'oh_scm_repo_', &block)
    Dir.mktmpdir(prefix, &block)
  end
end
